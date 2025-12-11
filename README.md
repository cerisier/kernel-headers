# Kernel Headers

Generate and publish vanilla Linux kernel header tarballs for every supported architecture and kernel version. The toolchain is intentionally minimal: a single `Makefile` orchestrates Docker builds, packaging, release publishing, and catalog generation.

## Requirements

- Docker
- `zstd` and `tar`
- `gh` CLI (only for the `release` target)
- `python3`

## Usage

All steps accept a space-separated list of versions through `VERSIONS="6.9.12 5.15.158"` or as positional arguments. When no versions are provided the scripts operate on everything under `build/` or `dist/`.

1. **Build headers**  
   ```sh
   make build VERSIONS="6.9.12 5.15.158"
   ```  
   Builds the requested versions via the unified `Dockerfile` and writes headers to `build/<version>/`.

2. **Package artifacts**  
   ```sh
   make package VERSIONS="6.9.12 5.15.158"
   ```  
   Produces per-version archives, `sha256sums.txt`, and `manifest.json` in `dist/<version>/`. Each manifest lists every asset and the deterministic GitHub download URL (`https://github.com/<owner>/<repo>/releases/download/<tag>/<file>`).

3. **Create a GitHub release**  
   ```sh
   make release VERSIONS="6.9.12 5.15.158"
   ```  
   Tags the repository (if needed) and uploads all files from `dist/<version>/` as release assets via `gh release create`.

4. **Update the catalog**  
   ```sh
   make catalog VERSIONS="6.9.12 5.15.158"
   ```  
   Merges the new manifest(s) into `catalog/index.json`, providing a single machine-readable index without relying on GitHub Pages.

Run `make help` for a quick summary of the commands.

## Supported Architectures

The default build includes:

```
alpha arc arm arm64 csky loongarch m68k mips openrisc powerpc riscv s390 sh sparc x86
```

Architectures such as hexagon or parisc require cross-compilers, so they are currently omitted. Override `ARCH_LIST` when invoking `build.sh` if you need a custom set.

## Supported Kernel Versions

Every kernel version ≥ 3.0 listed in `kernel_versions_latest_patch.txt` is supported. Older releases require different toolchains and are intentionally excluded from the default automation.

## Distribution Artifacts

Each release contains:

- Complete archives for an entire kernel version (`<version>-<date>.tar.{gz,zst}`)
- Per-architecture archives (`<version>-<arch>.tar.{gz,zst}`)
- `sha256sums.txt`
- `manifest.json`

`catalog/index.json` on the `main` branch aggregates every manifest, giving consumers a single JSON document they can periodically fetch instead of scraping GitHub releases or depending on GitHub Pages.
