#!/usr/bin/env bash
set -euo pipefail

RELEASE_DATE=${RELEASE_DATE:-$(date +%Y%m%d)}
REPOSITORY=${REPOSITORY:-cerisier/kernel-headers}
BUILD_DIR=${BUILD_DIR:-build}
DIST_DIR=${DIST_DIR:-dist}

TARGET_VERSIONS=()
if [[ $# -gt 0 ]]; then
    TARGET_VERSIONS=("$@")
elif [[ -n "${VERSIONS-}" ]]; then
    read -r -a TARGET_VERSIONS <<< "$VERSIONS"
elif [[ -d "$BUILD_DIR" ]]; then
    for dir in "$BUILD_DIR"/*; do
        [[ -d "$dir" ]] || continue
        TARGET_VERSIONS+=("$(basename "$dir")")
    done
fi

if [[ ${#TARGET_VERSIONS[@]} -eq 0 ]]; then
    echo "Nothing to archive" >&2
    exit 1
fi

sha256_for_file() {
    local path=$1
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$path" | awk '{print $1}'
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$path" | awk '{print $1}'
    else
        python3 - "$path" <<'PY'
import hashlib, sys
hasher = hashlib.sha256()
with open(sys.argv[1], "rb") as fh:
    for chunk in iter(lambda: fh.read(1024 * 1024), b""):
        hasher.update(chunk)
print(hasher.hexdigest())
PY
    fi
}

for version in "${TARGET_VERSIONS[@]}"; do
    version_dir="$BUILD_DIR/$version"
    if [[ ! -d "$version_dir" ]]; then
        echo "Missing build artifacts for $version" >&2
        continue
    fi

    tag_name="${version}-${RELEASE_DATE}"
    output_dir="$DIST_DIR/$version"
    rm -rf "$output_dir"
    mkdir -p "$output_dir"

    sha_file="$output_dir/sha256sums.txt"
    : > "$sha_file"
    manifest_rows=$(mktemp)

    record_asset() {
        local path=$1
        local kind=$2
        local arch=${3:--}
        local compression=${4:--}
        local add_to_checksums=${5:-true}
        local name
        name=$(basename "$path")
        local sha
        sha=$(sha256_for_file "$path")
        if [[ "$add_to_checksums" == "true" ]]; then
            printf "%s  %s\n" "$sha" "$name" >> "$sha_file"
        fi
        printf "%s\t%s\t%s\t%s\t%s\t%s\n" "$name" "$kind" "$arch" "$compression" "$path" "$sha" >> "$manifest_rows"
    }

    echo "Packaging $version as $tag_name"

    tar czf "$output_dir/${tag_name}.tar.gz" -C "$BUILD_DIR" "$version"
    record_asset "$output_dir/${tag_name}.tar.gz" "bundle" "-" "tar.gz"

    tar cf - -C "$BUILD_DIR" "$version" | zstd -19 -o "$output_dir/${tag_name}.tar.zst"
    record_asset "$output_dir/${tag_name}.tar.zst" "bundle" "-" "tar.zst"

    for arch_dir in "$version_dir"/*; do
        if [[ -d "$arch_dir" ]]; then
            arch_name=$(basename "$arch_dir")
            tar czf "$output_dir/${version}-${arch_name}.tar.gz" -C "$version_dir" "$arch_name"
            record_asset "$output_dir/${version}-${arch_name}.tar.gz" "arch" "$arch_name" "tar.gz"

            tar cf - -C "$version_dir" "$arch_name" | zstd -19 -o "$output_dir/${version}-${arch_name}.tar.zst"
            record_asset "$output_dir/${version}-${arch_name}.tar.zst" "arch" "$arch_name" "tar.zst"
        fi
    done

    record_asset "$sha_file" "checksum" "-" "txt" false

    ./scripts/render_manifest.py \
        --repo "$REPOSITORY" \
        --version "$version" \
        --tag "$tag_name" \
        --release-date "$RELEASE_DATE" \
        --artifact-file "$manifest_rows" \
        --output "$output_dir/manifest.json"

    rm -f "$manifest_rows"

done
