# Blackbeard FFmpeg

FFmpeg binaries and static libaries built using BtBn's build system

### Release Retention Policy

- The last build of each month is kept for two years.
- The last 14 daily builds are kept.
- The special "latest" build floats and provides consistent URLs always pointing to the latest build.

### Targets, Variants and Addins

Available targets:

- `win64` (x86_64 Windows)
- `linux64` (x86_64 Linux, glibc>=2.28, linux>=4.18)
- `linuxarm64` (arm64 (aarch64) Linux, glibc>=2.28, linux>=4.18)

The linuxarm64 target will not build some dependencies due to lack of arm64 (aarch64) architecture support or cross-compiling restrictions.

- `davs2` and `xavs2`: aarch64 support is broken.
- `libmfx` and `libva`: Library for Intel QSV, so there is no aarch64 support.

Available variants:

- `blackbeard` CUDA 13
- `blackbeard-legacy` CUDA 12
