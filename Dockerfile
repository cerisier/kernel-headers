ARG BASE_IMAGE=debian:bookworm
FROM ${BASE_IMAGE} AS base

ARG GCC_PACKAGE=gcc-12
ARG GCC_BIN=gcc-12
ARG EXTRA_PACKAGES=""

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        wget \
        xz-utils \
        libssl-dev \
        ca-certificates \
        ${GCC_PACKAGE} \
        make \
        libc6-dev \
        rsync \
        ${EXTRA_PACKAGES} && \
    rm -rf /var/lib/apt/lists/*

RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/${GCC_BIN} 100 && \
    update-alternatives --set gcc /usr/bin/${GCC_BIN}

FROM base AS builder

ARG KERNEL_VERSION
ARG ARCH_LIST="alpha arc arm arm64 csky loongarch m68k mips openrisc powerpc riscv s390 sh sparc x86"

WORKDIR /usr/src

RUN wget https://cdn.kernel.org/pub/linux/kernel/v${KERNEL_VERSION%%.*}.x/linux-${KERNEL_VERSION}.tar.xz && \
    tar -xf linux-${KERNEL_VERSION}.tar.xz && \
    rm linux-${KERNEL_VERSION}.tar.xz

WORKDIR /usr/src/linux-${KERNEL_VERSION}

RUN mkdir -p /build && \
    for arch in ${ARCH_LIST}; do \
        if [ -d arch/$arch ]; then \
            echo "Building headers for $arch..." && \
            make ARCH=$arch headers_install INSTALL_HDR_PATH=/build/$arch; \
        fi; \
    done

FROM scratch AS export
COPY --from=builder /build /build
COPY --from=builder /bin/true /bin/true
