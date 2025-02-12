FROM ubuntu:22.04 as builder

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive \
    apt-get install -y \
    build-essential wget autoconf bison lzip curl patchutils bc \
    flex texinfo help2man gawk libtool-bin ninja-build gperf zlib1g-dev \
    libncurses5-dev unzip python3 python3-pip python3-dev meson rsync git \
    pkg-config libtool autoconf-archive automake libmpfr-dev libexpat-dev \
    gettext libgettextpo-dev autotools-dev libmpc-dev libgmp-dev cmake \
    libglib2.0-dev libslirp-dev \
    # Perform cleanup
    && apt-get autoclean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -u 1000 -m -d /home/user -s /bin/bash user

USER user

WORKDIR /app

RUN git clone https://github.com/crosstool-ng/crosstool-ng.git \
    && cd crosstool-ng \
    && git checkout crosstool-ng-1.26.0 \
    && ./bootstrap \
    && ./configure --enable-local \
    && make

WORKDIR /app/crosstool-ng

RUN wget https://github.com/milkv-duo/duo-buildroot-sdk/archive/refs/tags/Duo-V1.1.1.tar.gz \
    && tar -xf Duo-V1.1.1.tar.gz \
    && rm Duo-V1.1.1.tar.gz \
    && mv duo-buildroot-sdk-Duo-V1.1.1 duo-buildroot-sdk

COPY .config /app/crosstool-ng/.config

RUN ./ct-ng build

FROM ubuntu:22.04 as cacher
ARG ARCHIVE=riscv64-unknown-linux-musl.tar.xz

WORKDIR /app

RUN useradd -u 1000 -m -d /home/user -s /bin/bash user

USER user

COPY --from=builder /app/crosstool-ng/${ARCHIVE} ${ARCHIVE}
