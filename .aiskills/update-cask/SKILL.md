---
name: update-cask
description: Create an update PR for an existing cask in homebrew-dotnet-sdk-versions. Use this skill whenever asked to manually bump a cask to a newer version, update sha256/url/version fields, force-update a cask the auto-updater missed, or open a PR to update a specific dotnet-sdk cask version.
---

# SKILL: Creating an Update PR for an Existing Cask

## When to use this skill
Use this skill whenever a user asks to:
- Manually update a cask to a newer version
- Create/open a PR to bump a cask version
- Update the sha256, url, or version in an existing cask
- Force-update a cask that the auto-updater missed or skipped

---

## Repository context

- **Repo**: `https://github.com/isen-ng/homebrew-dotnet-sdk-versions`
- **Casks**: `Casks/dotnet-sdk{MAJOR}-{MINOR}-{FEATURE}.rb` (versioned), `Casks/dotnet-sdk{MAJOR}.rb` (meta)
- **Release info source**: `https://raw.githubusercontent.com/dotnet/core/master/release-notes/{MAJOR}.{MINOR}/releases.json`
- **auto_updater.py** automates this weekly; use this skill for manual or out-of-band updates

---

## How auto_updater.py models versions

- `SdkVersion`: parses `"8.0.420"` → major=8, minor=0, feature=4, patch=20
- `RuntimeVersion`: parses `"8.0.12"` → major=8, minor=0, patch=12
- The `version` field in each cask is `"SDK_VERSION,RUNTIME_VERSION"` (two CSV values)
- `auto_updater.py` always stays within the same **feature band** (e.g. `8.0.4xx` → only considers `8.0.400`–`8.0.499`)
- For **preview** casks, `PreviewSdkVersion` handles version strings like `"11.0.100-preview.2.25101.1"`

---

## Method 1: Let auto_updater.py do the work (preferred)

### Dry run (verify what would change, no git operations)
```bash
./auto_updater.py
```

### Actually create PRs (runs git branch + push + `gh pr create`)
```bash
./auto_updater.py --really_push
```

This will:
1. Glob all `Casks/*.rb` (excluding preview)
2. For each cask, parse the current version, download `releases.json`
3. Find the highest patch in the same feature band
4. If newer: download the `.pkg`, verify SHA-512, compute SHA-256
5. Rewrite the cask file and `README.md`
6. Create a git branch `update-{file_path}-to-{new_version}` and open a PR

For **preview** casks only:
```bash
# auto_updater.py runs both Updater and PreviewUpdater at the end of __main__
./auto_updater.py --really_push
```

---

## Method 2: Manually update a single cask

Use this when the auto-updater is broken, the version has jumped a feature band, or you need a specific version.

### Step 1: Find the correct release data

```bash
curl -s https://raw.githubusercontent.com/dotnet/core/master/release-notes/8.0/releases.json \
  | python3 -c "
import json,sys
data = json.load(sys.stdin)
for r in data['releases']:
    sdk = r['sdk']['version']
    rt  = r['runtime']['version']
    print(sdk, rt)
" | head -20
```

Or browse: `https://github.com/dotnet/core/tree/main/release-notes`

### Step 2: Identify the correct download URLs and hashes

In `releases.json`, each release has an `sdk.files` array. Look for:
- `"name": "dotnet-sdk-osx-x64.pkg"` → get `url` and `hash` (SHA-512)
- `"name": "dotnet-sdk-osx-arm64.pkg"` → get `url` and `hash` (SHA-512)

### Step 3: Download and compute SHA-256

```bash
# For x64:
curl -L -o /tmp/sdk-x64.pkg "<x64_url>"
shasum -a 256 /tmp/sdk-x64.pkg   # → sha256
shasum -a 512 /tmp/sdk-x64.pkg   # → verify against releases.json hash

# For arm64:
curl -L -o /tmp/sdk-arm64.pkg "<arm64_url>"
shasum -a 256 /tmp/sdk-arm64.pkg
shasum -a 512 /tmp/sdk-arm64.pkg
```

**Always verify the SHA-512 matches `releases.json` before using the SHA-256.**

### Step 4: Update the cask file

For a **universal** (x64 + arm64) cask, update these fields:

```ruby
version "8.0.420,8.0.12"
sha256_x64    = "<new_x64_sha256>"
sha256_arm64  = "<new_arm64_sha256>"

url_x64   = "https://download.visualstudio.microsoft.com/download/pr/<new_guid>/dotnet-sdk-#{version.csv.first}-osx-x64.pkg"
url_arm64 = "https://download.visualstudio.microsoft.com/download/pr/<new_guid>/dotnet-sdk-#{version.csv.first}-osx-arm64.pkg"
```

For an **Intel-only** cask, update:

```ruby
version "5.0.408,5.0.17"
sha256 "<new_x64_sha256>"

url "https://download.visualstudio.microsoft.com/download/pr/<new_guid>/dotnet-sdk-#{version.csv.first}-osx-x64.pkg"
```

**Important**: The URL must still contain `#{version.csv.first}` interpolation — replace only the GUID and keep the interpolation.

### Step 5: Update README.md

In `README.md`, find the version table row for this cask and update the SDK version number. Example:

```
| `dotnet-sdk8-0-400` | 8.0.419 | x64 & arm64 |  |
```
→
```
| `dotnet-sdk8-0-400` | 8.0.420 | x64 & arm64 |  |
```

### Step 6: Validate locally

```bash
brew tap isen-ng/dotnet-sdk-versions $PWD
brew style Casks/dotnet-sdk8-0-400.rb
brew audit --cask dotnet-sdk8-0-400
```

### Step 7: Open the PR

```bash
git checkout -b update-Casks/dotnet-sdk8-0-400.rb-to-8.0.420
git add Casks/dotnet-sdk8-0-400.rb README.md
git commit -m "[Auto] update Casks/dotnet-sdk8-0-400.rb from 8.0.419 to 8.0.420"
git push origin update-Casks/dotnet-sdk8-0-400.rb-to-8.0.420
gh pr create --base master \
  --head update-Casks/dotnet-sdk8-0-400.rb-to-8.0.420 \
  --title "[Auto] update Casks/dotnet-sdk8-0-400.rb from 8.0.419 to 8.0.420" \
  --body ""
```

---

## After a versioned cask PR is merged: update the meta cask

Meta casks (`dotnet-sdk8.rb` etc.) are auto-generated from the latest versioned cask in each major version. After merging a versioned cask update, run:

```bash
./auto_meta_updater.py
./auto_meta_updater.py --really_commit --really_push
```

This regenerates `Casks/dotnet-sdk{MAJOR}.rb` and updates the meta version table in `README.md`.

---

## Key rules and gotchas

- **Feature band lock**: `auto_updater.py` will NOT cross feature bands. `dotnet-sdk8-0-400` only tracks `8.0.4xx` — it will never be updated to `8.0.500`. A new cask `dotnet-sdk8-0-500` must be created for that.
- **SHA-512 verification is mandatory**: Always verify the downloaded SHA-512 matches `releases.json` before trusting the SHA-256. This guards against MITM attacks.
- **URL interpolation**: The URL in the cask must contain `#{version.csv.first}` — replace only the GUID portion, not the version substring.
- **Branch naming convention**: `update-{file_path}-to-{new_version}` (matches what auto_updater uses, important for auto_committer to pick up).
- **Commit message convention**: `[Auto] update {file_path} from {old_version} to {new_version}` — auto_committer.py uses this pattern to find and merge PRs.
- **README must be updated** in the same commit as the cask file — auto_committer expects both in one commit.
- **Meta casks are never manually updated** — always use `auto_meta_updater.py`.
- **Do not cross-update multiple casks in one PR** — each cask gets its own branch and PR so CI can test them independently.
