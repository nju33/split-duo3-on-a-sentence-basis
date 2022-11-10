#!/usr/bin/env bash

set -eu

if ! command -v ffmpeg; then
    echo -e "Please install ffmpeg"
    exit 1
fi

cleanup() {
    set +e
    # delete all once created mp3s
    rm out/*.mp3
    set -e
}

extract() {
    # disc:delay:duration
    local -a durations=(
        "1:3:4"
        "1:0:5"
        "1:0:7"
        "1:0:7"
        "1:0:5"
        "1:0:5"
        "1:1:7"
        "1:1:4"
        "1:0:7"
        "2:3:6"
        "2:0:7"
        "2:0:5"
        "2:0:7"
        "2:0:5"
        "2:0:6"
        "2:0:5"
        "2:1:5"
        "2:0:6"
        "2:1:6"
        "2:1:7"
        "2:0:5"
        "3:4:6"
    )
    local -i sum=0
    local -r lyrics_file="lyrics.txt"

    for ((i = 0; i < ${#durations[@]}; ++i)); do
        {
            IFS=":"
            # shellcheck disable=SC2086
            set -- ${durations[$i]}
        }
        local -i disc="$1"
        local -i track="$((i + 1))"
        local -i delay="$2"
        sum=$((sum + delay))

        local -i current="$3"

        local -A ss=(
            ["hour"]=$(printf "%02d" $((sum / 3600)))
            ["minute"]=$(printf "%02d" $((sum / 60)))
            ["second"]=$(printf "%02d" $((sum % 60)))
        )
        local lyrics
        lyrics="$(sed -n $((i + 1))p ${lyrics_file})"

        local output # e.g. 001.mp3
        output="out/$(printf "%03d" $((i + 1))).mp3"

        (
            set -x
            # ffmpeg -i in.mp3 -i artwork.png -map 0:a -map 1:v -c:v:1 png -c copy -disposition:1 attached_pic -id3v2_version 3 \
            ffmpeg -i in.mp3 -i artwork.png -acodec copy \
                -loglevel warning \
                -metadata "title"="$lyrics" \
                -metadata "disc"="$disc" \
                -metadata "track"="$track" \
                `# not working` \
                -metadata "lyrics"="$lyrics" \
                `# For Meta app used to the below tag but it’s not working` \
                -metadata "lyrics-XXX"="$lyrics" \
                -metadata "comments"="$lyrics" \
                -ss "${ss["hour"]}:${ss["minute"]}:${ss["second"]}" \
                -t "${current}" \
                "$output"
        )

        sum=$((sum + current))
    done
}

cleanup
extract
