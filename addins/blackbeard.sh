#!/bin/bash
FF_CONFIGURE="${FF_CONFIGURE} --disable-ffplay --enable-pic"

ffbuild_dockeraddin() {
    to_df 'ENV CPLUS_INCLUDE_PATH=/opt/ffbuild/include'
}

package_variant() {
    IN="$1"
    OUT="$2"

    if [[ "$BUILD_NAME" == *shared* ]]; then
        mkdir -p "$OUT"/bin
        cp "$IN"/bin/* "$OUT"/bin

        mkdir -p "$OUT"/lib
        cp -a "$IN"/lib/* "$OUT"/lib

        sed -i \
            -e 's|^prefix=.*|prefix=${pcfiledir}/../..|' \
            -e 's|/ffbuild/prefix|${prefix}|' \
            -e '/Libs.private:/d' \
            "$OUT"/lib/pkgconfig/*.pc

        mkdir -p "$OUT"/include
        cp -r "$IN"/include/* "$OUT"/include
    else
        cp "$IN"/bin/* "$OUT"
    fi
}
