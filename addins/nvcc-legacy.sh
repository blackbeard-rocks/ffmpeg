#!/bin/bash
FF_CONFIGURE="${FF_CONFIGURE} --enable-cuda-nvcc"
NV_ARCH=$(uname -m | grep -q "x86" && echo "x86_64" || echo "aarch64")
NV_VER="12.9.1"

ffbuild_dockeraddin() {
    to_df 'RUN apt-get -y update && \
        apt-get -y install --no-install-recommends gcc-12 g++-12 && \
        apt-get -y clean autoclean && \
        rm -rf /var/lib/apt/lists/*'
    to_df "ENV NV_VER=\"${NV_VER}\""
    to_df "ENV NV_ARCH=\"${NV_ARCH}\""
    to_df 'RUN --mount=src=patches/blackbeard/nvidia.py,dst=/nvidia.py /nvidia.py --label "${NV_VER}" --product cuda --output "/opt/cuda-${NV_VER}" --os linux --arch "${NV_ARCH}" --component cuda_nvcc'
    to_df 'RUN --mount=src=patches/blackbeard/nvidia.py,dst=/nvidia.py /nvidia.py --label "${NV_VER}" --product cuda --output "/opt/cuda-${NV_VER}" --os linux --arch "${NV_ARCH}" --component cuda_cudart'
    to_df 'RUN --mount=src=patches/blackbeard/nvidia.py,dst=/nvidia.py /nvidia.py --label "${NV_VER}" --product cuda --output "/opt/cuda-${NV_VER}" --os linux --arch "${NV_ARCH}" --component libcurand'
    to_df 'RUN --mount=src=patches/blackbeard/nvidia.py,dst=/nvidia.py /nvidia.py --label "${NV_VER}" --product cuda --output "/opt/cuda-${NV_VER}" --os linux --arch "${NV_ARCH}" --component cuda_cccl'
    to_df 'RUN --mount=src=patches/blackbeard/vmaf/glibc.patch,dst=/glibc.patch patch -p0 math_functions.h -d "/opt/cuda-${NV_VER}/linux-${NV_ARCH}/include/crt" </glibc.patch'
    to_df 'ENV NVCC_APPEND_FLAGS="-ccbin=/usr/bin/gcc-12"'
    to_df 'ENV NVCC_PREPEND_FLAGS="-I/opt/ffbuild/include"'
    to_df 'ENV CUDA_PATH="/opt/cuda-${NV_VER}/linux-${NV_ARCH}"'
    to_df 'ENV CUDA_HOME="/opt/cuda-${NV_VER}/linux-${NV_ARCH}"'
    to_df 'ENV PATH="${PATH}:/opt/cuda-${NV_VER}/linux-${NV_ARCH}/bin"'
}
