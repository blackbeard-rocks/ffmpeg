# Libvmaf patches
if [[ "$STAGENAME" == *vmaf ]]; then
    # NVCC
    if [[ "$ADDINS_STR" == *nvcc* ]]; then
        sed -i '/exe_wrapper/d' /cross.meson
        sed -i '/^\[binaries\]/a cuda = '"'nvcc'"'' /cross.meson

        myconf+=(
            -Denable_zimg=true
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
        # curl -sL "https://github.com/Netflix/vmaf/compare/f85a853692a8c730d0270cd733c8bb30b5b93b7c...lawrencecurtis:vmaf:cuda3.patch" | git apply -v
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

    perl -0777 -i -pe 's/(static int copy_picture_data\(AVFrame \*src, VmafPicture \*dst, unsigned bpc\)\s*\{.*?)(\s*return 0;\s*\})/$1\n\n    switch (src->color_range) {\n    case AVCOL_RANGE_MPEG:\n        dst->color.range = VMAF_COLOR_RANGE_LIMITED;\n        break;\n    case AVCOL_RANGE_JPEG:\n        dst->color.range = VMAF_COLOR_RANGE_FULL;\n        break;\n    default:\n        dst->color.range = VMAF_COLOR_RANGE_UNKNOWN;\n        break;\n    }\n\n    switch (src->color_primaries) {\n    case AVCOL_PRI_BT709:\n        dst->color.primaries = VMAF_COLOR_PRIMARIES_BT709;\n        break;\n    case AVCOL_PRI_BT2020:\n        dst->color.primaries = VMAF_COLOR_PRIMARIES_BT2020;\n        break;\n    case AVCOL_PRI_SMPTE432:\n        dst->color.primaries = VMAF_COLOR_PRIMARIES_SMPTE432;\n        break;\n    default:\n        dst->color.primaries = VMAF_COLOR_PRIMARIES_UNKNOWN;\n        break;\n    }\n\n    switch (src->color_trc) {\n    case AVCOL_TRC_BT709:\n        dst->color.trc = VMAF_COLOR_TRC_BT709;\n        break;\n    case AVCOL_TRC_SMPTE2084:\n    case AVCOL_TRC_ARIB_STD_B67:\n        dst->color.trc = VMAF_COLOR_TRC_SMPTE2084;\n        break;\n    default:\n        dst->color.trc = VMAF_COLOR_TRC_UNKNOWN;\n        break;\n    }\n\n    switch (src->colorspace) {\n    case AVCOL_SPC_BT709:\n        dst->color.matrix = VMAF_COLOR_MATRIX_BT709;\n        break;\n    case AVCOL_SPC_BT2020_NCL:\n    case AVCOL_SPC_BT2020_CL:\n        dst->color.matrix = VMAF_COLOR_MATRIX_BT2020_NCL;\n        break;\n    case AVCOL_SPC_ICTCP:\n        dst->color.matrix = VMAF_COLOR_MATRIX_ICTCP;\n        break;\n    default:\n        dst->color.matrix = VMAF_COLOR_MATRIX_UNKNOWN;\n        break;\n    }$2/s' libavfilter/vf_libvmaf.c


    echo "🩹 All patches applied successfully."
fi
