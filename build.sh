#!/bin/bash

set -x

trap 'echo "Interrupted!"; exit 1' SIGINT

# versions.sh
KERNEL_VERSION_FILE="kernel_versions_latest_patch.txt"

if [[ -n "$1" ]]; then
    KERNEL_VERSIONS=("$1")
else
    # Latest patch for all minors
    KERNEL_VERSIONS=(
        # Skip the 12 first versions (<3.0)
        # $(tail -n +12 ${KERNEL_VERSION_FILE})
		$(git diff --unified=0 ${KERNEL_VERSION_FILE} | sed -n 's/^\+\(.*\)/\1/p' | grep -v '+')
    )
fi

for version in "${KERNEL_VERSIONS[@]}"; do

    # skip if already built
    if [[ -d "build/$version" ]]; then
        echo "Headers for $version already built, skipping..."
        continue
    fi

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
    docker cp extract-headers-$version:/build ./build/$version
    docker rm extract-headers-$version

done
