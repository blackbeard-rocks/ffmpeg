FROM ubuntu:25.10

ARG TARGETPLATFORM

ENV DEBIAN_FRONTEND=noninteractive
RUN \
    apt-get -y update && \
    apt-get -y dist-upgrade && \
    apt-get -y install --no-install-recommends \
        $([ "$TARGETPLATFORM" != "linux/amd64" ] || echo gcc-multilib g++-multilib) \
        build-essential yasm nasm \
        xxd pkgconf curl wget unzip zip git subversion mercurial rsync jq \
        autoconf automake libtool libtool-bin autopoint gettext cmake meson ninja-build \
        clang llvm lcov lld qemu-user \
        texinfo texi2html help2man flex bison groff \
        gperf itstool ragel libc6-dev zlib1g-dev libssl-dev \
        gtk-doc-tools gobject-introspection gawk \
        ocaml ocaml-findlib ocamlbuild libnum-ocaml-dev indent p7zip-full zstd \
        python3-setuptools python3-pip python3-venv python3-jinja2 python3-jsonschema python3-apt python3-dev python-is-python3 && \
    curl -fsSL https://deb.nodesource.com/setup_24.x | bash - && \
    apt-get -y install nodejs && \
    apt-get -y install --no-install-recommends gcc-12 g++-12 && \
    apt-get -y autoremove && \
    apt-get -y clean autoclean && \
    rm -rf /var/lib/apt/lists/* && \
    git config --global user.email "builder@localhost" && \
    git config --global user.name "Builder" && \
    git config --global advice.detachedHead false

ENV CARGO_HOME="/opt/cargo" RUSTUP_HOME="/opt/rustup" PATH="/opt/cargo/bin:${PATH}"
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y --no-modify-path && \
    cargo install cargo-c && rm -rf "${CARGO_HOME}"/registry "${CARGO_HOME}"/git

RUN --mount=src=.,dst=/input \
    for s in /input/*.sh; do cp $s /usr/bin/$(echo $s | sed -e 's|.*/||' -e 's/\.sh$//'); done

ENV HOST_CC="gcc" \
    HOST_CXX="g++" \
    HOST_CFLAGS="-O2 -pipe" \
    HOST_CXXFLAGS="-O2 -pipe"

# ---- Install nvcc and CUDA libraries ----
RUN mkdir /tmp/cuda && cd /tmp/cuda \
    && wget -O nvidia.py https://raw.githubusercontent.com/NVIDIA/build-system-archive-import-examples/refs/heads/main/parse_redist.py \
    && chmod +x nvidia.py \
    && wget -O math.patch https://raw.githubusercontent.com/stefantalpalaru/gentoo-overlay/75b7793fdc88314165ca28c75b557defcb38f6d8/dev-util/nvidia-cuda-toolkit/files/nvidia-cuda-toolkit-glibc-2.42.patch \
    && NV_ARCH=$(uname -m | grep -q "x86" && echo "x86_64" || echo "aarch64") \
    NV_VER="12.9.1" \
    && ./nvidia.py --label ${NV_VER} --product cuda --output /usr/local/cuda-${NV_VER} --os linux --arch ${NV_ARCH} --component cuda_nvcc \
    && ./nvidia.py --label ${NV_VER} --product cuda --output /usr/local/cuda-${NV_VER} --os linux --arch ${NV_ARCH} --component cuda_cudart \
    && ./nvidia.py --label ${NV_VER} --product cuda --output /usr/local/cuda-${NV_VER} --os linux --arch ${NV_ARCH} --component libcurand \
    && ./nvidia.py --label ${NV_VER} --product cuda --output /usr/local/cuda-${NV_VER} --os linux --arch ${NV_ARCH} --component cuda_cccl \
    && cd /usr/local/cuda-${NV_VER}/linux-${NV_ARCH}/include/crt \
    && patch -p1 math_functions.h </tmp/cuda/math.patch \
    && cd /tmp/cuda \
    && NV_ARCH=$(uname -m | grep -q "x86" && echo "x86_64" || echo "sbsa") \
    NV_VER="13.1.0" \
    && ./nvidia.py --label ${NV_VER} --product cuda --output /usr/local/cuda-${NV_VER} --os linux --arch ${NV_ARCH} --component cuda_nvcc \
    && ./nvidia.py --label ${NV_VER} --product cuda --output /usr/local/cuda-${NV_VER} --os linux --arch ${NV_ARCH} --component cuda_cudart \
    && ./nvidia.py --label ${NV_VER} --product cuda --output /usr/local/cuda-${NV_VER} --os linux --arch ${NV_ARCH} --component cuda_crt \
    && ./nvidia.py --label ${NV_VER} --product cuda --output /usr/local/cuda-${NV_VER} --os linux --arch ${NV_ARCH} --component libnvvm \
    && cd /usr/local/cuda-${NV_VER}/linux-${NV_ARCH}/include/crt \
    && patch -p1 math_functions.h </tmp/cuda/math.patch \
    && rm -rfv /tmp/cuda
