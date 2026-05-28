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
curl -s https://raw.githubusercontent.com/dotnet/core/master/release-notes/10.0/releases.json \
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

### Step 2: Get the download URLs and hashes

**For .NET 6+ (universal casks):** The URL follows a predictable pattern — no GUID needed:
```
https://builds.dotnet.microsoft.com/dotnet/Sdk/{SDK_VERSION}/dotnet-sdk-{SDK_VERSION}-osx-x64.pkg
https://builds.dotnet.microsoft.com/dotnet/Sdk/{SDK_VERSION}/dotnet-sdk-{SDK_VERSION}-osx-arm64.pkg
```

In `releases.json`, the `sdk.files` array contains the SHA-512 hashes for verification. Look for:
- `"name": "dotnet-sdk-osx-x64.pkg"` → get `hash` (SHA-512)
- `"name": "dotnet-sdk-osx-arm64.pkg"` → get `hash` (SHA-512)

**For .NET 5 and earlier (Intel-only casks):** The URL contains a GUID that must be fetched from `releases.json`:
- `"name": "dotnet-sdk-osx-x64.pkg"` → get both `url` and `hash` (SHA-512)

### Step 3: Download and compute SHA-256

```bash
# For .NET 6+ x64:
SDK_VERSION="10.0.204"
curl -L -o /tmp/sdk-x64.pkg "https://builds.dotnet.microsoft.com/dotnet/Sdk/${SDK_VERSION}/dotnet-sdk-${SDK_VERSION}-osx-x64.pkg"
shasum -a 256 /tmp/sdk-x64.pkg   # → sha256
shasum -a 512 /tmp/sdk-x64.pkg   # → verify against releases.json hash

# For .NET 6+ arm64:
curl -L -o /tmp/sdk-arm64.pkg "https://builds.dotnet.microsoft.com/dotnet/Sdk/${SDK_VERSION}/dotnet-sdk-${SDK_VERSION}-osx-arm64.pkg"
shasum -a 256 /tmp/sdk-arm64.pkg
shasum -a 512 /tmp/sdk-arm64.pkg
```

**Always verify the SHA-512 matches `releases.json` before using the SHA-256.**

### Step 4: Update the cask file

For a **universal** (.NET 6+) cask, update these fields:

```ruby
version "10.0.204,10.0.8"

sha256_x64 = "<new_x64_sha256>"
sha256_arm64 = "<new_arm64_sha256>"
url_x64 = "https://builds.dotnet.microsoft.com/dotnet/Sdk/#{version.csv.first}/dotnet-sdk-#{version.csv.first}-osx-x64.pkg"
url_arm64 = "https://builds.dotnet.microsoft.com/dotnet/Sdk/#{version.csv.first}/dotnet-sdk-#{version.csv.first}-osx-arm64.pkg"
on_arm do
  sha256 sha256_arm64

  url url_arm64
end
on_intel do
  sha256 sha256_x64

  url url_x64
end
```

For an **Intel-only** (.NET 5 and earlier) cask, update:

```ruby
version "5.0.408,5.0.17"
sha256 "<new_x64_sha256>"

url "https://download.visualstudio.microsoft.com/download/pr/<new_guid>/dotnet-sdk-#{version.csv.first}-osx-x64.pkg"
```

**Important**: The URL must still contain `#{version.csv.first}` interpolation — replace only the GUID portion, not the version substring.

### Step 5: Update README.md

In `README.md`, find the version table row for this cask and update the SDK version number. Example:

```
| `dotnet-sdk10-0-200` | 10.0.203 | x64 & arm64 |  |
```
→
```
| `dotnet-sdk10-0-200` | 10.0.204 | x64 & arm64 |  |
```

### Step 6: Validate locally

```bash
brew tap isen-ng/dotnet-sdk-versions $PWD
brew style Casks/dotnet-sdk10-0-200.rb
brew audit --cask dotnet-sdk10-0-200
```

### Step 7: Open the PR

```bash
git checkout -b update-Casks/dotnet-sdk10-0-200.rb-to-10.0.204
git add Casks/dotnet-sdk10-0-200.rb README.md
git commit -m "[Auto] update Casks/dotnet-sdk10-0-200.rb from 10.0.203 to 10.0.204"
git push origin update-Casks/dotnet-sdk10-0-200.rb-to-10.0.204
gh pr create --base master \
  --head update-Casks/dotnet-sdk10-0-200.rb-to-10.0.204 \
  --title "[Auto] update Casks/dotnet-sdk10-0-200.rb from 10.0.203 to 10.0.204" \
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
- **URL format for .NET 6+**: Use `https://builds.dotnet.microsoft.com/dotnet/Sdk/#{version.csv.first}/dotnet-sdk-#{version.csv.first}-osx-{arch}.pkg`. There is no GUID. Do NOT use the old `download.visualstudio.microsoft.com/download/pr/<guid>/...` format for modern casks.
- **URL interpolation**: The URL in the cask must contain `#{version.csv.first}` interpolation.
- **`uninstall pkgutil:`** takes a single string, not an array.
- **`zap`** must include both `pkgutil:` array and `trash: ["~/.dotnet", "~/.nuget", "/etc/paths.d/dotnet", "/etc/paths.d/dotnet-cli-tools"]`.
- **Branch naming convention**: `update-{file_path}-to-{new_version}` (matches what auto_updater uses, important for auto_committer to pick up).
- **Commit message convention**: `[Auto] update {file_path} from {old_version} to {new_version}` — auto_committer.py uses this pattern to find and merge PRs.
- **README must be updated** in the same commit as the cask file — auto_committer expects both in one commit.
- **Meta casks are never manually updated** — always use `auto_meta_updater.py`.
- **Do not cross-update multiple casks in one PR** — each cask gets its own branch and PR so CI can test them independently.
