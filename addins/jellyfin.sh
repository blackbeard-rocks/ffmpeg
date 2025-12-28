#!/bin/bash

ffbuild_dockeraddin() {
    to_df 'RUN apt-get -y update && \
        apt-get -y install --no-install-recommends quilt && \
        apt-get -y clean autoclean && \
        rm -rf /var/lib/apt/lists/*'
    to_df 'ENV CPLUS_INCLUDE_PATH=/opt/ffbuild/include'
}
