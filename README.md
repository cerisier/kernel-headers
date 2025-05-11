# Kernel Headers

A tool to generate and distribute Linux kernel headers for any architectures and kernel versions.
The headers are generated vanilla, and may require further patching for userland usage.

### Supported Architectures

For now, only the following architectures are generated:
* alpha
* arc
* arm
* arm64
* csky
* loongarch
* m68k
* mips
* openrisc
* powerpc
* riscv
* s390
* sh
* sparc
* x86

Other architectures like hexagon, parisc were producing `gcc: error` because
`gcc` is invoked using flags that are only available if it was compiled for
the target architecture.

For now, this project uses a dummy approach of using the host `gcc`, only
the architectures that did not produce a single `gcc: error` as part of their
headers generation were kept.

TODO(cerisier): Support all architectures the right way, using cross compiler when needed.

### Supported Kernel Versions

All versions >= 3.0

> Supporting older kernels requires tweaking how we list supported architectures
> as well as installing a compatible version of gcc.

### Distributed Tarballs

This project distributes headers for the latest patch of each minor kernel version. Previously generated headers are retained, so from the date of this project’s release onward, this repository will provide headers for all kernel versions.

Visit https://cerisier.github.io/kernel-headers/
