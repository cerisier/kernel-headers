#!/usr/bin/env bash
set -euo pipefail

# — EDIT these two to match your repo
REPO="cerisier/linux-headers"
OUTPUT_DIR="gh-pages-out"

# clean slate
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# 1. fetch all releases (name, publishedAt)
releases_json=$(gh release list --repo "$REPO" --json name,publishedAt --limit 1000)

# 2. extract unique “versions” (strip off final -YYYYMMDD)
versions=($(
    echo "$releases_json" \
        | jq -r '.[].name
                         | capture("(?<ver>.*)-[0-9]{8}$")?
                         | select(.ver)
                         | .ver' \
        | sort -uV
))

# Helper function to format file size
format_size() {
  size=$1
  if (( size < 1024 )); then
    echo "$size B"
  elif (( size < 1048576 )); then
    printf "%.0fK" $(echo "scale=0; $size/1024" | bc)
  else
    printf "%.0fM" $(echo "scale=0; $size/1048576" | bc)
  fi
}

# 3. start root index.html
cat > "$OUTPUT_DIR/index.html" <<EOF
<!DOCTYPE html>
<html>
<head><title>Index of /</title></head>
<body>
<h1>Index of /</h1><hr><pre>
EOF

# 4. for each version, pick newest and build its page
for ver in "${versions[@]}"; do
  # find the release name with the max publishedAt
  latest=$(echo "$releases_json" \
    | jq -r --arg V "$ver" '
        map(select(.name | test("^"+$V+"-[0-9]{8}$")))
        | max_by(.publishedAt)
        | .name
    '
  )
  echo "→ $ver → $latest"

  # fetch that release's assets
  assets_json=$(gh release view "$latest" --repo "$REPO" --json assets,publishedAt)

  # make folder
  mkdir -p "$OUTPUT_DIR/$ver"

  # write per-version index.html
  cat > "$OUTPUT_DIR/$ver/index.html" <<EOF
<!DOCTYPE html>
<html>
<head><title>Index of /$ver/</title></head>
<body>
<h1>Index of /$ver/</h1><hr><pre><a href="../">../</a>
EOF

  # append each asset as a link
  asset_lines=$(echo "$assets_json" | jq -r '.assets[] | [.name, .url, .size, .updatedAt] | @tsv')

  while IFS=$'\t' read -r asset_name asset_url asset_size asset_updated_at; do
    asset_date=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$asset_updated_at" +"%d-%b-%Y %H:%M")
    formatted_size=$(format_size "$asset_size")
    line="<a href=\"$asset_url\">$asset_name</a>$(printf ' %*s' $((50 - ${#asset_name})) ) $asset_date    $formatted_size"
    echo "$line" >> "$OUTPUT_DIR/$ver/index.html"
  done <<< "$asset_lines"

  # close that HTML
  cat >> "$OUTPUT_DIR/$ver/index.html" <<EOF
</pre><hr></body>
</html>
EOF

  # add to root index
  echo "<a href=\"$ver/index.html\">$ver/</a>" >> "$OUTPUT_DIR/index.html"
done

# 5. close root HTML
cat >> "$OUTPUT_DIR/index.html" <<EOF
</pre><hr></body>
</html>
EOF

# 6. publish to gh-pages branch
# git checkout --orphan gh-pages
# git rm -rf .
# cp -R "$OUTPUT_DIR"/* .
# git add .
# git commit -m "chore: regenerate gh-pages release index"
# git push -u origin gh-pages --force

echo "✅ gh-pages branch updated!"
