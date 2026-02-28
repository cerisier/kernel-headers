#!/bin/sh

for dir in \
    v1.0 \
    v1.1 \
    v1.2 \
    v1.3 \
    v2.0 \
    v2.1 \
    v2.2 \
    v2.3 \
    v2.4 \
    v2.5 \
    v2.6 \
    v3.x \
    v4.x \
    v5.x \
    v6.x \
    v7.x; \
    do curl -s -L https://mirrors.edge.kernel.org/pub/linux/kernel/$dir; \
done \
  | grep -oE '(linux|patch|ChangeLog)-[0-9]+\.[0-9]+(\.[0-9]+)?' \
  | sed -E 's/^(linux|patch|ChangeLog)-//' \
  | sort -uV > kernel_versions.txt

awk -F. '
{
    key = $1"."$2
    patch = $3 + 0
    if (key in max_patch) {
        if (patch > max_patch[key]) {
            max_patch[key] = patch
        }
    } else {
        max_patch[key] = patch
    }
}
END {
    for (k in max_patch) {
        print k"."max_patch[k]
    }
}
' kernel_versions.txt | sort -uV > kernel_versions_latest_patch.txt
