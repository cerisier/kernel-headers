# Linux Headers

A tool to generate Linux kernel headers for any architectures and kernel versions.
The headers are generated vanilla, and may require further patching for userland usage.

### Supported Architectures
The tool supports generating headers for the following architectures:

* alpha
* arm
* arm64
* csky
* hexagon
* loongarch
* m68k
* mips
* powerpc
* riscv
* s390
* sh
* sparc
* x86

### Supported Kernel Versions

All versions after 3.10.x

### Distributed Tarballs

This project distributes headers for stable and long-term kernel versions as
defined by https://kernel.org/.

For now:
* 5.4.293
* 5.10.237
* 5.15.181
* 6.1.137
* 6.6.89
* 6.12.27
* 6.13.12
* 6.14.5
