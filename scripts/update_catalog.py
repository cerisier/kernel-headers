#!/usr/bin/env python3
import argparse
import datetime as dt
import json
from pathlib import Path
from typing import Dict, Any


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Update catalog/index.json from manifest files.")
    parser.add_argument("manifests", nargs="+", help="List of manifest.json paths to merge")
    parser.add_argument(
        "--output",
        default="catalog/index.json",
        help="Path to the aggregated catalog file",
    )
    return parser.parse_args()


def version_key(value: str) -> tuple:
    parts = []
    for piece in value.split("."):
        try:
            parts.append(int(piece))
        except ValueError:
            parts.append(piece)
    return tuple(parts)


def main() -> None:
    args = parse_args()
    output_path = Path(args.output)
    catalog: Dict[str, Any] = {"versions": {}}
    if output_path.exists():
        catalog = json.loads(output_path.read_text())
        catalog.setdefault("versions", {})

    for manifest_path in args.manifests:
        data = json.loads(Path(manifest_path).read_text())
        catalog["versions"][data["version"]] = data

    ordered = {
        version: catalog["versions"][version]
        for version in sorted(catalog["versions"], key=version_key)
    }
    catalog["versions"] = ordered
    catalog["generated_at"] = dt.datetime.utcnow().isoformat(timespec="seconds") + "Z"

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(catalog, indent=2) + "\n")


if __name__ == "__main__":
    main()
