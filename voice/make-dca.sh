#!/bin/bash
set -e
ffmpeg -i $1 -f s16le -ar 48000 -ac 2 pipe:1 | ~/go/bin/dca > ${1/.mp3/}.dca
