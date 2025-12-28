#!/bin/bash

package_variant() {
    IN="$1"
    OUT="$2"

    mkdir -p "$OUT"
    cp "$IN"/bin/* "$OUT"

    # mkdir -p "$OUT/doc"
    # cp -r "$IN"/share/doc/ffmpeg/* "$OUT"/doc

    # mkdir -p "$OUT/presets"
    # cp "$IN"/share/ffmpeg/*.ffpreset "$OUT"/presets
}
