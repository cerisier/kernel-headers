# Linux Headers

A tool to generate Linux kernel headers for any architectures and kernel versions.
The headers are generated vanilla, and may require further patching for userland usage.

### Supported Architectures

All architectures available for a given versions are .

### Supported Kernel Versions

All versions >= 3.0

> Supporting older kernels requires tweaking how we list supported architectures
> as well as installing a compatible version of gcc.

### Distributed Tarballs

This project distributes headers for the latest patch of each minor kernel version. Previously generated headers are retained, so from the date of this project’s release onward, this repository will provide headers for all kernel versions.
