# Libvmaf patches
if [[ "$TARGET" != "winarm64" && "$STAGENAME" == *vmaf ]]; then
    myconf+=(
        --cross-file=/cross.meson
        -Denable_asm=true
        -Dc_args="-DUSE_DIRECT_READ -DVMAF_BATCH_THREADING -DOC_NEW_STYLE_INCLUDES ${CFLAGS}"
    )

    # NVCC
    if [[ "$ADDINS_STR" == *nvcc* ]]; then
        sed -i '/exe_wrapper/d' /cross.meson
        sed -i '/^\[binaries\]/a cuda = '"'nvcc'"'' /cross.meson

        myconf+=(
            -Denable_nvcc=true
            -Denable_cuda=true
        )

        cd ..
        if [[ "$ADDINS_STR" == *nvcc-legacy* && "$ADDINS_STR" != *sycl* ]]; then
            git apply /patches/vmaf-nvcc-legacy.patch
        elif [[ "$ADDINS_STR" == *nvcc* && "$ADDINS_STR" != *sycl* ]]; then
            git apply /patches/vmaf-nvcc.patch
        fi
        cd build
    fi

    # VULKAN
    if [[ "$ADDINS_STR" == *vulkan* ]]; then
        myconf+=(
            -Denable_vulkan=enabled
        )
    fi

    # SYCL
    if [[ "$ADDINS_STR" == *sycl* ]]; then
        myconf+=(
            -Denable_sycl=true
        )
        # 1. Get the target triple directly from the compiler
        CTNG_TARGET=$(${CC} -dumpmachine)

        # 2. Find the absolute root of the toolchain by going one level up from the 'bin' folder
        CTNG_TOOLCHAIN=$(dirname $(dirname $(which ${CC})))
        export CTNG_TOOLCHAIN

        # 3. Get the sysroot (which you already figured out)
        CTNG_SYSROOT=$(${CC} -print-sysroot)

        # 4. Generate the config
        ICPXCFG=$(mktemp)
        export ICPXCFG
        echo "-static-intel --sysroot $CTNG_SYSROOT --gcc-toolchain=$CTNG_TOOLCHAIN --target=$CTNG_TARGET" >"$ICPXCFG"
    fi

# FFmpeg patches
elif [[ -z "$STAGENAME" ]]; then

    # JellyFin
    if [[ "$ADDINS_STR" == *jellyfin* ]]; then
        PATCH_REPO="https://github.com/nyanmisaka/jellyfin-ffmpeg.git"
        PATCH_BRANCH="jellyfin-8.1" # branch that contains the patches
        git clone --depth 1 -b "$PATCH_BRANCH" "$PATCH_REPO" "/tmp/jellyfin-ffmpeg"
        export QUILT_PATCHES="/tmp/jellyfin-ffmpeg/debian/patches"
        quilt push -a
        if quilt status | grep -q 'Unapplied'; then
            echo "ERROR: Some patches failed to apply. Check quilt status for details." >&2
            exit 1
        fi
        if [[ "$TARGET" == *win* ]]; then
            FF_CONFIGURE="${FF_CONFIGURE} --disable-vaapi"
        fi
    fi

    # SYCL or Vulkan
    if [[ "$ADDINS_STR" == *sycl* || "$ADDINS_STR" == *vulkan* ]]; then
        PATCH_REPO="https://github.com/lusoris/vmaf.git"
        PATCH_BRANCH="master" # branch that contains the patches
        git clone --depth 1 -b "$PATCH_BRANCH" "$PATCH_REPO" "/tmp/vmaf-sycl"
        export QUILT_PATCHES="/tmp/vmaf-sycl/ffmpeg-patches"

        for p in $(grep -v '^\s*#' ${QUILT_PATCHES}/series.txt); do
            git apply --3way ${QUILT_PATCHES}/$p
        done
    fi

    # NVCC
    if [[ "$ADDINS_STR" == *nvcc* ]]; then
        git apply /patches/ffmpeg-gpl-compat.patch
    fi

    if [[ "$ADDINS_STR" == *nvcc-legacy* ]]; then
        git apply /patches/ffmpeg-nvcc-legacy.patch
    elif [[ "$ADDINS_STR" == *nvcc* ]]; then
        git apply /patches/ffmpeg-nvcc.patch
    fi

    if [[ -d "$FFBUILD_PREFIX/bundle" ]]; then
        cp -rav $FFBUILD_PREFIX/bundle /ffbuild/prefix/
    fi

    echo "🩹 All patches applied successfully."
fi
