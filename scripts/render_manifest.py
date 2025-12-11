#!/usr/bin/env python3
import argparse
import datetime as dt
import json
from pathlib import Path
from typing import Any, Dict, List


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Render manifest metadata for a release.")
    parser.add_argument("--repo", required=True, help="owner/repo pair")
    parser.add_argument("--version", required=True, help="semantic version (e.g. 6.9.12)")
    parser.add_argument("--tag", required=True, help="release tag name")
    parser.add_argument("--release-date", required=True, help="date portion used in the tag (YYYYMMDD)")
    parser.add_argument("--artifact-file", required=True, help="TSV describing generated artifacts")
    parser.add_argument("--output", required=True, help="Where to write the manifest JSON")
    return parser.parse_args()


def load_artifacts(path: Path, repo: str, tag: str) -> List[Dict[str, Any]]:
    artifacts: List[Dict[str, Any]] = []
    for line in path.read_text().splitlines():
        if not line.strip():
            continue
        name, kind, arch, compression, artifact_path, sha = line.split("\t")
        entry = {
            "name": name,
            "kind": kind,
            "size": Path(artifact_path).stat().st_size,
            "sha256": sha,
            "url": f"https://github.com/{repo}/releases/download/{tag}/{name}",
        }
        if arch and arch != "-":
            entry["arch"] = arch
        if compression and compression != "-":
            entry["compression"] = compression
        artifacts.append(entry)
    artifacts.sort(key=lambda item: (item.get("kind", ""), item.get("arch", ""), item["name"]))
    return artifacts


def main() -> None:
    args = parse_args()
    artifacts = load_artifacts(Path(args.artifact_file), args.repo, args.tag)
    manifest = {
        "version": args.version,
        "tag": args.tag,
        "release_date": args.release_date,
        "repository": args.repo,
        "generated_at": dt.datetime.utcnow().isoformat(timespec="seconds") + "Z",
        "assets": artifacts,
    }
    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(manifest, indent=2) + "\n")


if __name__ == "__main__":
    main()
