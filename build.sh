#!/bin/bash

set -x

# versions.sh
KERNEL_VERSION_FILE="kernel_versions.txt"

# Read kernel versions from file, ignoring comments and empty lines
# readarray -t KERNEL_VERSIONS < <(grep -v '^#' "$KERNEL_VERSION_FILE" | grep -v '^\s*$' )

# Latest patch for all minors
KERNEL_VERSIONS=(
    # 3.10.108
    # 3.11.10
    # 3.12.74
    # 3.13.11
    # 3.14.79
    # 3.15.10
    # 3.16.85
    # 3.17.8
    # 3.18.140
    # 3.19.8

    # 4.0.9
    # 4.1.52
    # 4.2.8
    # 4.3.6
    # 4.4.302
    # 4.5.7
    # 4.6.7
    # 4.7.10
    # 4.8.17
    # 4.9.337
    # 4.10.17
    # 4.11.12
    # 4.12.14
    # 4.13.16
    # 4.14.336
    # 4.15.18
    # 4.16.18
    # 4.17.19
    # 4.18.20
    # 4.19.325
    # 4.20.17

    # 5.0.21
    # 5.1.21
    # 5.2.21
    # 5.3.18
    # 5.4.293
    # 5.5.19
    # 5.6.19
    # 5.7.19
    # 5.8.18
    # 5.9.16
    # 5.10.237
    # 5.11.22
    # 5.12.19
    # 5.13.19
    # 5.14.21
    # 5.15.181
    # 5.16.20
    # 5.17.15
    # 5.18.19
    # 5.19.17

    # 6.0.19
    # 6.1.137
    # 6.2.16
    # 6.3.13
    # 6.4.16
    # 6.5.13
    # 6.6.89
    # 6.7.12
    # 6.8.12
    # 6.9.12
    # 6.10.14
    # 6.11.11
    # 6.12.27
    # 6.13.12
    # 6.14.5

    # 5.4.293
    # 5.10.237
    # 5.15.181
    # 6.1.137
    # 6.6.89
    # 6.12.27
    # 6.13.12
    # 6.14.5
)

for version in "${KERNEL_VERSIONS[@]}"; do
    echo "Building headers for Linux $version..."

    if [[ "$version" == 3.* ]]; then
        DOCKERFILE="3.x/Dockerfile"
    elif [[ "$version" == 4.* ]]; then
        DOCKERFILE="4.x/Dockerfile"
    elif [[ "$version" == 5.* ]]; then
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
