#!/bin/bash
SCRIPT_REPO="https://github.com/Netflix/vmaf.git"
SCRIPT_COMMIT=$(git ls-remote $SCRIPT_REPO | grep "HEAD" | awk '{print $1}')

SYCL_REPO="https://github.com/lusoris/vmaf.git"
SYCL_COMMIT=$(git ls-remote $SYCL_REPO | grep "HEAD" | awk '{print $1}')

ffbuild_enabled() {
    return 0
}

ffbuild_depends() {
    echo base
    echo ffnvcodec
    if [[ "$ADDINS_STR" == *vulkan* ]]; then
        echo vulkan
    fi
    if [[ "$ADDINS_STR" == *sycl* ]]; then
        echo level-zero
        echo vaapi
    fi
}

ffbuild_dockerdl() {
    default_dl netflix
    echo "git-mini-clone \"$SYCL_REPO\" \"$SYCL_COMMIT\" lusoris"
}

ffbuild_dockerstage() {
    to_df "RUN --mount=src=${SELF},dst=/stage.sh --mount=src=${SELFCACHE},dst=/cache.tar.xz --mount=src=patches/blackbeard,dst=/patches run_stage /stage.sh"
}

ffbuild_dockerbuild() {
    if [[ "$ADDINS_STR" == *lusoris* || "$ADDINS_STR" == *vulkan* ]]; then
        cd lusoris
    else
        cd netflix
    fi

    # Kill build of unused and broken tools
    echo >libvmaf/tools/meson.build

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

    source /patches/blackbeard.sh
    meson "${myconf[@]}" ../libvmaf ../libvmaf/build || cat ../libvmaf/build/meson-logs/meson-log.txt
    ninja -j"$(nproc)" -C ../libvmaf/build

    echo "oh"
    DESTDIR="$FFBUILD_DESTDIR" ninja install -C ../libvmaf/build

    #exit 1
    export BUNDLE_DIR="$FFBUILD_DESTPREFIX/bundle"
    mkdir -p "$BUNDLE_DIR/lib"
    mkdir -p "$BUNDLE_DIR/include"
    echo "here 3"

    cp -rav "$FFBUILD_DESTPREFIX"/lib/libvmaf* "$BUNDLE_DIR/lib"
    cp -rav "$FFBUILD_DESTPREFIX"/include/libvmaf "$BUNDLE_DIR/include"

    sed -i 's/Libs.private:/Libs.private: -lstdc++/; t; $ a Libs.private: -lstdc++' "$FFBUILD_DESTPREFIX"/lib/pkgconfig/libvmaf.pc
}

ffbuild_configure() {
    (($(ffbuild_ffver) >= 501)) || return 0
    echo --enable-libvmaf
}

ffbuild_unconfigure() {
    echo --disable-libvmaf
}
