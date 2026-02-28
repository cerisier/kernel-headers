#!/usr/bin/env bash
set -euo pipefail

DIST_DIR=${DIST_DIR:-dist}
REPOSITORY=${REPOSITORY:-cerisier/kernel-headers}

collect_versions() {
    local -n _out=$1
    shift || true
    if [[ $# -gt 0 ]]; then
        _out=("$@")
    elif [[ -n "${VERSIONS-}" ]]; then
        read -r -a _out <<< "$VERSIONS"
    elif [[ -d "$DIST_DIR" ]]; then
        for dir in "$DIST_DIR"/*; do
            [[ -d "$dir" ]] || continue
            _out+=("$(basename "$dir")")
        done
    fi
}

manifests_for_version() {
    local version=$1
    echo "$DIST_DIR/$version/manifest.json"
}

read_manifest_field() {
    local manifest=$1
    local field=$2
    python3 - "$manifest" "$field" <<'PY'
import json, sys
path, field = sys.argv[1], sys.argv[2]
with open(path) as fh:
    data = json.load(fh)
value = data
for part in field.split('.'):
    value = value.get(part) if isinstance(value, dict) else None
print(value if value is not None else "")
PY
}

create_tag_if_needed() {
    local tag=$1
    if git rev-parse "$tag" >/dev/null 2>&1; then
        return
    fi
    git tag "$tag"
    if git config --get remote.origin.url >/dev/null; then
        git push origin "$tag"
    fi
}

release_versions=()
collect_versions release_versions "$@"

if [[ ${#release_versions[@]} -eq 0 ]]; then
    echo "No versions to release" >&2
    exit 1
fi

shopt -s nullglob

for version in "${release_versions[@]}"; do
    manifest_path=$(manifests_for_version "$version")
    if [[ ! -f "$manifest_path" ]]; then
        echo "Missing manifest for $version" >&2
        continue
    fi

    tag=$(read_manifest_field "$manifest_path" tag)
    release_date=$(read_manifest_field "$manifest_path" release_date)

    if gh release view "$tag" --repo "$REPOSITORY" >/dev/null 2>&1; then
        echo "Release $tag already exists, skipping"
        continue
    fi

    create_tag_if_needed "$tag"

    output_dir="$DIST_DIR/$version"
    assets=("$output_dir"/*.tar.gz "$output_dir"/*.tar.zst "$output_dir"/sha256sums.txt "$output_dir"/manifest.json)
    filtered_assets=()
    for asset in "${assets[@]}"; do
        [[ -f "$asset" ]] && filtered_assets+=("$asset")
    done
    if [[ ${#filtered_assets[@]} -eq 0 ]]; then
        echo "No assets for $version" >&2
        continue
    fi

    notes="Linux $version headers built on ${release_date}"
    gh release create "$tag" \
        --repo "$REPOSITORY" \
        --title "$tag" \
        --notes "$notes" \
        "${filtered_assets[@]}"
done
