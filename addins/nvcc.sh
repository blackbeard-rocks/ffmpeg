#!/bin/bash
FF_CONFIGURE+=" --enable-cuda-nvcc"

NV_VER=13.1.0
NV_ARCH=$(uname -m | grep -q "x86" && echo "x86_64" || echo "sbsa")
