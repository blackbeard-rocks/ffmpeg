#!/bin/bash

SCRIPT_REPO="https://github.com/lawrencecurtis/vmaf.git"
SCRIPT_COMMIT="23e072f72617fb7e308b1eebcfc943836dfc336e"

ffbuild_enabled() {
    return 0
}

ffbuild_depends() {
    echo base
    echo ffnvcodec
}

ffbuild_dockerstage() {
    to_df "RUN --mount=src=${SELF},dst=/stage.sh --mount=src=${SELFCACHE},dst=/cache.tar.xz --mount=src=patches/blackbeard,dst=/patches run_stage /stage.sh"
}

ffbuild_dockerbuild() {
    # Kill build of unused and broken tools
    # echo >libvmaf/tools/meson.build

    sed -i -E 's/([^.>:_[:alnum:]])swap\(/\1libsvm_swap(/g' libvmaf/src/svm.cpp
    sed -i -E 's/([^.>:_[:alnum:]])min\(/\1libsvm_min(/g' libvmaf/src/svm.cpp
    sed -i -E 's/([^.>:_[:alnum:]])max\(/\1libsvm_max(/g' libvmaf/src/svm.cpp

    mkdir build && cd build

    local myconf=(
        --prefix="$FFBUILD_PREFIX"
        --buildtype=release
        --default-library=static
        -Dbuilt_in_models=true
        -Denable_tests=false
        -Denable_docs=false
        -Denable_float=true
    )

    if [[ $TARGET == *32 ]]; then
        myconf+=(
            -Denable_avx512=false
            -Denable_asm=false
        )
    else
        myconf+=(
            -Denable_avx512=true
            -Denable_asm=true
        )
    fi

    if [[ $TARGET == win* || $TARGET == linux* ]]; then
        myconf+=(
            --cross-file=/cross.meson
        )
    else
        echo "Unknown target"
        return -1
    fi

    # newest things

    source /patches/blackbeard.sh
    meson "${myconf[@]}" ../libvmaf ../libvmaf/build || cat ../libvmaf/build/meson-logs/meson-log.txt
    ninja -j"$(nproc)" -C ../libvmaf/build

    DESTDIR="$FFBUILD_DESTDIR" ninja install -C ../libvmaf/build

    sed -i 's/Libs.private:/Libs.private: -lstdc++/; t; $ a Libs.private: -lstdc++' "$FFBUILD_DESTPREFIX"/lib/pkgconfig/libvmaf.pc
}

ffbuild_configure() {
    (($(ffbuild_ffver) >= 501)) || return 0
    echo --enable-libvmaf
}

ffbuild_unconfigure() {
    echo --disable-libvmaf
}
