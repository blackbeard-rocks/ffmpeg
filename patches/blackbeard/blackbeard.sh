# Libvmaf patches
if [[ "$STAGENAME" == *vmaf ]]; then
    # NVCC
    if [[ "$ADDINS_STR" == *nvcc* ]]; then
        sed -i '/exe_wrapper/d' /cross.meson
        sed -i '/^\[binaries\]/a cuda = '"'nvcc'"'' /cross.meson

        myconf+=(
            -Denable_nvcc=true
            -Denable_cuda=true
            -Denable_tools=false
        )

        cd ..
        if [[ "$ADDINS_STR" == *nvcc-legacy* && "$ADDINS_STR" != *sycl* ]]; then
            git apply -v /patches/vmaf/nvcc-legacy.patch
        elif [[ "$ADDINS_STR" == *nvcc* && "$ADDINS_STR" != *sycl* ]]; then
            git apply -v /patches/vmaf/nvcc.patch
        fi
        curl -sL "https://github.com/Netflix/vmaf/compare/master...lawrencecurtis:vmaf:cuda.patch" | git apply -v
        cd build || exit
    fi

# FFmpeg patches
elif [[ -z "$STAGENAME" ]]; then

    if [[ "$ADDINS_STR" == *8.1* ]]; then
        BASE="/patches/ffmpeg/8.1"
    else
        BASE="/patches/ffmpeg/9.0"
    fi

    # NVCC
    if [[ $BASE && "$ADDINS_STR" == *nvcc* ]]; then
        git apply -v "$BASE/gpl-compat.patch"
    fi

    if [[ $BASE && "$ADDINS_STR" == *nvcc-legacy* ]]; then
        git apply -v "$BASE/nvcc-legacy.patch"
    elif [[ $BASE && "$ADDINS_STR" == *nvcc* ]]; then
        git apply -v "$BASE/nvcc.patch"
    fi

    if [[ $BASE && "$TARGET" == winarm64 ]]; then
        git apply -v "$BASE/winarm64.patch"
    fi

    if [[ -d "$FFBUILD_PREFIX/bundle" ]]; then
        cp -rav "$FFBUILD_PREFIX/bundle" /ffbuild/prefix/
    fi

    echo "🩹 All patches applied successfully."
fi
