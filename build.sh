#!/usr/bin/env bash
set -euo pipefail

trap 'echo "Interrupted!"; exit 1' SIGINT

KERNEL_VERSION_FILE=${KERNEL_VERSION_FILE:-kernel_versions_latest_patch.txt}
BUILD_DIR=${BUILD_DIR:-build}
DOCKERFILE=${DOCKERFILE:-Dockerfile}
ARCH_LIST=${ARCH_LIST:-"alpha arc arm arm64 csky loongarch m68k mips openrisc powerpc riscv s390 sh sparc x86"}

KERNEL_VERSIONS=()
if [[ $# -gt 0 ]]; then
    KERNEL_VERSIONS=("$@")
elif [[ -n "${VERSIONS-}" ]]; then
    read -r -a KERNEL_VERSIONS <<< "$VERSIONS"
else
    if [[ ! -f "$KERNEL_VERSION_FILE" ]]; then
        echo "Missing $KERNEL_VERSION_FILE" >&2
        exit 1
    fi
    while IFS= read -r line; do
        [[ -n "$line" ]] && KERNEL_VERSIONS+=("$line")
    done < <(awk -F. '$1 + 0 >= 3 {print}' "$KERNEL_VERSION_FILE")
fi

if [[ ${#KERNEL_VERSIONS[@]} -eq 0 ]]; then
    echo "No kernel versions provided" >&2
    exit 1
fi

compute_build_args() {
    local version=$1
    local major=${version%%.*}
    case "$major" in
        3)
            echo "--build-arg BASE_IMAGE=debian:buster --build-arg GCC_PACKAGE=gcc-7 --build-arg GCC_BIN=gcc-7"
            ;;
        4|5|6|7|8|9)
            echo "--build-arg BASE_IMAGE=debian:bookworm --build-arg GCC_PACKAGE=gcc-12 --build-arg GCC_BIN=gcc-12"
            ;;
        *)
            echo ""
            ;;
    esac
}

for version in "${KERNEL_VERSIONS[@]}"; do
    if [[ -z "$version" ]]; then
        continue
    fi

    if [[ -d "${BUILD_DIR}/${version}" ]]; then
        echo "Headers for $version already built, skipping."
        continue
    fi

    build_args=$(compute_build_args "$version")
    if [[ -z "$build_args" ]]; then
        echo "Unsupported version: $version" >&2
        continue
    fi

    echo "Building headers for Linux $version..."

    docker build \
        --progress=plain \
        --build-arg KERNEL_VERSION="$version" \
        --build-arg ARCH_LIST="$ARCH_LIST" \
        $build_args \
        -f "$DOCKERFILE" \
        -t "kernel-headers:${version}" .

    mkdir -p "$BUILD_DIR"
    container_name="extract-headers-${version}"
    docker create --name "$container_name" "kernel-headers:${version}" /bin/true >/dev/null
    docker cp "$container_name":/build "${BUILD_DIR}/${version}"
    docker rm "$container_name" >/dev/null

done
