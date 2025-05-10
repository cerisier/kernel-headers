#/bin/sh

curl -s https://cdn.kernel.org/pub/linux/kernel/ \
  | grep -o -E 'v[3-6]\.x' \
  | sort -u \
  | while read dir; \
      do curl -s -L https://cdn.kernel.org/pub/linux/kernel/$dir; \
    done \
  | grep -oE '\b[0-9]+\.[0-9]+\.[0-9]+\b' \
  | sort -uV \
> kernel_versions.txt

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
' all_versions.txt | sort -uV > kernel_versions_latest_patch.txt
