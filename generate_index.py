import subprocess
import json
import re
from collections import defaultdict

# CONFIGURE THIS
OWNER = "cerisier"
REPO = "kernel-headers"
RELEASE_PATTERN = re.compile(r"(?P<version>\d+\.\d+\.\d+)-(?P<date>\d{8})")
ASSET_PATTERN = re.compile(r"(?P<version>\d+\.\d+\.\d+)-(?P<arch>[^.]+)\.(tar\.(gz|zst))")

def run_gh_command(args):
    result = subprocess.run(["gh"] + args, capture_output=True, text=True, check=True)
    return json.loads(result.stdout)

# Step 1: Get all releases using gh CLI
releases = run_gh_command(["release", "list", "--repo", f"{OWNER}/{REPO}", "--limit", "1000", "--json", "tagName"])

# Step 2: Keep only the latest release per version
latest_by_version = {}

for release in releases:
    tag = release["tagName"]
    match = RELEASE_PATTERN.match(tag)
    if not match:
        continue
    version = match.group("version")
    date = match.group("date")
    if version not in latest_by_version or latest_by_version[version]["date"] < date:
        latest_by_version[version] = {
            "tag": tag,
            "date": date,
        }

print(latest_by_version)

# Step 3: Build the index
index = defaultdict(dict)

for version, info in latest_by_version.items():
    tag = info["tag"]
    release_data = run_gh_command(["release", "view", tag, "--repo", f"{OWNER}/{REPO}", "--json", "assets"])
    assets = release_data.get("assets", [])

    sha256sums_asset = next((a for a in assets if a["name"] == "sha256sums.txt"), None)
    if not sha256sums_asset:
        continue

    # Download sha256sums.txt
    sha_url = sha256sums_asset["url"]
    sha_resp = subprocess.run(["gh", "api", sha_url, "--header", "Accept: application/octet-stream"], capture_output=True, text=True, check=True)
    lines = sha_resp.stdout.strip().splitlines()
    checksums = {}
    for line in lines:
        sha, filename = line.strip().split(maxsplit=1)
        checksums[filename] = sha

    for asset in assets:
        match = ASSET_PATTERN.match(asset["name"])
        if not match:
            continue
        arch = match.group("arch")
        sha = checksums.get(asset["name"])
        if not sha:
            continue
        index[version][arch] = {
            "url": asset["url"],
            "sha256": sha,
        }

# Output the final JSON
print(json.dumps(index, indent=4))
