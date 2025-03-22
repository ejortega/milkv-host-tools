FROM ubuntu:22.04 AS builder
ARG CROSSTOOL_VER=crosstool-ng-1.27.0
ARG DUO_BUILDROOT_VER=2.0.0
ARG MUSL_VER=1.2.4

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

RUN wget https://github.com/crosstool-ng/crosstool-ng/releases/download/${CROSSTOOL_VER}/${CROSSTOOL_VER}.tar.xz \
    && tar xvf ${CROSSTOOL_VER}.tar.xz \
    && mv ${CROSSTOOL_VER} crosstool-ng \
    && cd crosstool-ng \
    && ./bootstrap \
    && ./configure --enable-local \
    && make

WORKDIR /app/crosstool-ng

COPY .config /app/crosstool-ng/.config

RUN wget https://github.com/milkv-duo/duo-buildroot-sdk-v2/archive/refs/tags/v${DUO_BUILDROOT_VER}.tar.gz \
    && tar -xf v${DUO_BUILDROOT_VER}.tar.gz \
    && rm v${DUO_BUILDROOT_VER}.tar.gz \
    && mkdir -p patches/musl/${MUSL_VER} \
    && cp duo-buildroot-sdk-v2-${DUO_BUILDROOT_VER}/buildroot-2024.02/package/musl/*.patch patches/musl/${MUSL_VER}/ \
    && ./ct-ng build \
    && rm -rf duo-buildroot-sdk-v2-${DUO_BUILDROOT_VER}

FROM ubuntu:22.04 AS cacher
ARG ARCHIVE=riscv64-unknown-linux-musl.tar.xz

WORKDIR /app

RUN useradd -u 1000 -m -d /home/user -s /bin/bash user

USER user

COPY --from=builder /app/crosstool-ng/${ARCHIVE} ${ARCHIVE}
