#!/bin/bash

set -x

# versions.sh
KERNEL_VERSION_FILE="kernel_versions.txt"

# Read kernel versions from file, ignoring comments and empty lines
# readarray -t KERNEL_VERSIONS < <(grep -v '^#' "$KERNEL_VERSION_FILE" | grep -v '^\s*$' )

KERNEL_VERSIONS=(
    5.4.293
    5.10.237
    5.15.181
    6.1.137
    6.6.89
    6.12.27
    6.13.12
    6.14.5
)

for version in "${KERNEL_VERSIONS[@]}"; do
    echo "Building headers for Linux $version..."

    if [[ "$version" == 5.* ]]; then
        DOCKERFILE="5.x/Dockerfile"
    elif [[ "$version" == 6.* ]]; then
        DOCKERFILE="6.x/Dockerfile"
    else
        echo "Unsupported version: $version"
        continue
    fi

    docker build \
        --progress=plain \
        --build-arg KERNEL_VERSION=$version \
        -f $DOCKERFILE \
        -t kernel-headers:$version .;

    mkdir -p build
    docker create --name extract-headers-$version kernel-headers:$version /bin/true
    docker cp extract-headers-$version:/build ./build/headers-$version
    docker rm extract-headers-$version

done
