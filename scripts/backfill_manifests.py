#!/usr/bin/env python3
import argparse
import hashlib
import json
import re
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, Tuple

TAG_PATTERN = re.compile(r"(?P<version>\d+\.\d+\.\d+)-(?P<date>\d{8})")


def gh_json(args: List[str]) -> dict:
    result = subprocess.run(["gh"] + args, check=True, capture_output=True, text=True)
    return json.loads(result.stdout)


def gh_bytes(args: List[str]) -> bytes:
    result = subprocess.run(["gh"] + args, check=True, capture_output=True)
    return result.stdout


def parse_sha_file(content: str) -> Dict[str, str]:
    mapping: Dict[str, str] = {}
    for line in content.strip().splitlines():
        if not line.strip():
            continue
        sha, filename = line.strip().split(maxsplit=1)
        mapping[filename.strip()] = sha
    return mapping


def classify_asset(name: str, version: str, date: str) -> Tuple[str, str, str]:
    if name == "sha256sums.txt":
        return "checksum", "-", "txt"

    compression = ""
    base = name
    for suffix in (".tar.gz", ".tar.zst"):
        if name.endswith(suffix):
            compression = suffix.lstrip(".")
            base = name[: -len(suffix)]
            break

    if not compression:
        return "other", "-", "-"

    if base == f"{version}-{date}":
        return "bundle", "-", compression

    prefix = f"{version}-"
    if base.startswith(prefix):
        arch = base[len(prefix) :]
        return "arch", arch, compression

    return "other", "-", compression


def ensure_dir(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=True)


def compute_sha_from_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def build_manifest_entry(asset: dict, sha: str, kind: str, arch: str, compression: str) -> dict:
    entry = {
        "name": asset["name"],
        "kind": kind,
        "size": asset.get("size"),
        "sha256": sha,
        "url": asset["url"],
    }
    if arch and arch != "-":
        entry["arch"] = arch
    if compression and compression != "-":
        entry["compression"] = compression
    return entry


def main() -> None:
    parser = argparse.ArgumentParser(description="Backfill manifest files from existing GitHub releases.")
    parser.add_argument("--repo", required=True, help="Repository in owner/name form.")
    parser.add_argument("--dist-dir", default="dist", help="Where to store generated manifest files.")
    parser.add_argument("--force", action="store_true", help="Overwrite existing manifest.json files.")
    parser.add_argument("--limit", type=int, default=1000, help="Limit for gh release list.")
    args = parser.parse_args()

    dist_dir = Path(args.dist_dir)
    ensure_dir(dist_dir)

    releases = gh_json(["release", "list", "--repo", args.repo, "--limit", str(args.limit), "--json", "tagName"])

    for release in releases:
        tag = release.get("tagName")
        if not tag:
            continue
        match = TAG_PATTERN.match(tag)
        if not match:
            continue
        version = match.group("version")
        date = match.group("date")
        version_dir = dist_dir / version
        manifest_path = version_dir / "manifest.json"
        if manifest_path.exists() and not args.force:
            continue

        release_data = gh_json(["release", "view", tag, "--repo", args.repo, "--json", "assets"])
        assets = release_data.get("assets", [])
        sha_asset = next((a for a in assets if a["name"] == "sha256sums.txt"), None)
        if not sha_asset:
            continue

        sha_bytes = gh_bytes(["api", sha_asset["apiUrl"], "--header", "Accept: application/octet-stream"])
        checksums = parse_sha_file(sha_bytes.decode("utf-8"))
        sha_for_summary = compute_sha_from_bytes(sha_bytes)

        manifest_assets: List[dict] = []
        for asset in assets:
            name = asset["name"]
            kind, arch, compression = classify_asset(name, version, date)
            if name == "sha256sums.txt":
                entry = build_manifest_entry(asset, sha_for_summary, kind, arch, compression)
                manifest_assets.append(entry)
                continue

            sha_value = checksums.get(name)
            if not sha_value:
                continue
            entry = build_manifest_entry(asset, sha_value, kind, arch, compression)
            manifest_assets.append(entry)

        manifest_assets.sort(key=lambda item: (item.get("kind", ""), item.get("arch", ""), item["name"]))

        generated_at = datetime.now(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")

        manifest = {
            "version": version,
            "tag": tag,
            "release_date": date,
            "repository": args.repo,
            "generated_at": generated_at,
            "assets": manifest_assets,
        }

        ensure_dir(version_dir)
        manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")
        print(f"wrote {manifest_path}")


if __name__ == "__main__":
    main()
