FROM debian:buster AS builder

ARG KERNEL_VERSION=6.9

# Install dependencies
RUN apt-get update && \
    apt-get install --allow-unauthenticated -y --no-install-recommends \
        wget xz-utils libssl-dev ca-certificates gcc-7 make libc6-dev rsync && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src

RUN wget https://cdn.kernel.org/pub/linux/kernel/v${KERNEL_VERSION%%.*}.x/linux-${KERNEL_VERSION}.tar.xz && \
    tar -xf linux-${KERNEL_VERSION}.tar.xz && rm linux-${KERNEL_VERSION}.tar.xz

WORKDIR /usr/src/linux-${KERNEL_VERSION}

RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 100 && \
    update-alternatives --set gcc /usr/bin/gcc-7

RUN mkdir -p /build && \
    for arch in \
        alpha \
        arm \
        arm64 \
        csky \
        hexagon \
        loongarch \
        m68k \
        mips \
        powerpc \
        riscv \
        s390 \
        sh \
        sparc \
        x86; do \
        if [ -d arch/$arch ]; then \
            echo "Building headers for $arch..." && \
            make ARCH=$arch headers_install INSTALL_HDR_PATH=/build/$arch; \
        fi \
    done

FROM scratch AS export
COPY --from=builder /build /build
COPY --from=builder /bin/true /bin/true
