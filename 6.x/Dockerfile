FROM debian:bookworm AS base

# Install dependencies
RUN apt-get update && \
    apt-get install --allow-unauthenticated -y --no-install-recommends \
        wget xz-utils libssl-dev ca-certificates gcc-12 make libc6-dev rsync && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 100 && \
update-alternatives --set gcc /usr/bin/gcc-12

FROM base AS builder

ARG KERNEL_VERSION=6.9

WORKDIR /usr/src

RUN wget https://cdn.kernel.org/pub/linux/kernel/v${KERNEL_VERSION%%.*}.x/linux-${KERNEL_VERSION}.tar.xz && \
    tar -xf linux-${KERNEL_VERSION}.tar.xz && rm linux-${KERNEL_VERSION}.tar.xz

WORKDIR /usr/src/linux-${KERNEL_VERSION}

RUN mkdir -p /build && \
    for arch in $(ls arch | grep -v Kconfig); do \
        if [ -d arch/$arch ]; then \
            echo "Building headers for $arch..." && \
            make ARCH=$arch headers_install INSTALL_HDR_PATH=/build/$arch; \
        fi \
    done

FROM scratch AS export
COPY --from=builder /build /build
COPY --from=builder /bin/true /bin/true
