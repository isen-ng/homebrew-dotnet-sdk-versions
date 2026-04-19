# SKILL: Fixing CI for homebrew-dotnet-sdk-versions

## When to use this skill
Use this skill whenever a user asks to:
- Fix a broken CI workflow
- Investigate a CI failure in the `continuous-integration` workflow
- Update `.github/workflows/ci.yml`
- Understand why CI steps are failing
- Sync or adapt the CI from the official Homebrew cask

---

## Critical: The CI is intentionally derived from the official Homebrew cask CI

**This is the single most important thing to know when fixing CI.**

The CI workflow at `.github/workflows/ci.yml` in this repo is **closely modeled after** the official Homebrew cask CI:

> **Official reference**: `https://github.com/Homebrew/homebrew-cask/blob/main/.github/workflows/ci.yml`

When CI is broken, **always check the official cask CI first** to see if there are upstream fixes, new steps, updated action versions, or changed behavior that this repo needs to adopt.

This is explicitly documented in `CONTRIBUTING.md`:
> "If CI is broken, there is a good chance that we can find updates from the official cask CI that fixes our CI."

---

## Workflow structure overview

### This repo's CI (`isen-ng/homebrew-dotnet-sdk-versions`)

```
jobs:
  generate-matrix   # runs on ubuntu-latest; generates matrix of casks to test from the PR diff
  test              # runs on macOS; for each cask: style, audit, install, uninstall
  conclusion        # summarises pass/fail
```

**Key differences from the official CI:**
- `generate-matrix` runs on `ubuntu-latest` (official uses `macos-latest`)
- Adds a `brew tap isen-ng/dotnet-sdk-versions` step so the tap is registered before checkout
- Only triggers on `pull_request` to `master` (not on push or `workflow_dispatch`)
- Does not use `concurrency` group cancellation
- Does not have the snapshot/comparison of installed apps step (the official CI added this later)
- Does not use pinned SHA hashes on `actions/checkout` and `actions/cache`
- Uses `actions/checkout@v6` and `actions/cache@v5` (unpinned)

### Official CI (`Homebrew/homebrew-cask`) — reference version

```
jobs:
  generate-matrix   # runs on macos-latest; also supports workflow_dispatch
  test              # runs on macOS; fetch → audit → gather info → install → snapshot comparison → uninstall
  conclusion        # runs on ubuntu-slim
```

**Notable additions in the official CI not yet in this repo's CI:**
- `workflow_dispatch` trigger with manual cask input
- `concurrency` group to cancel in-progress runs on new pushes
- `permissions: contents: read`
- `brew test-bot --cleanup --only-cleanup-before` step
- `brew fetch --cask` step before audit
- Style cache (`~/Library/Caches/Homebrew/style`)
- Snapshot of installed/running apps before and after install, with a diff comparison
- Pinned action SHA hashes (security best practice)
- `ubuntu-slim` for `conclusion` job (saves cost)

---

## How to investigate and fix a CI failure

### Step 1: Read the failure

Look at which step failed in the GitHub Actions log:
- `brew readall` — usually a Ruby syntax error in a cask
- `brew audit` — audit policy violation (URL format, sha256 mismatch, etc.)
- `brew style` — RuboCop style violation in the cask
- `Gather cask information` — Ruby eval error in the cask's `brew ruby` block
- `brew install --cask` — actual install failure (download, pkg, pkgutil)
- `brew uninstall --cask` — uninstall failure

### Step 2: Check the official CI for upstream fixes

Fetch the latest official CI:
```
https://github.com/Homebrew/homebrew-cask/blob/main/.github/workflows/ci.yml
```

Compare with this repo's CI:
```
https://github.com/isen-ng/homebrew-dotnet-sdk-versions/blob/master/.github/workflows/ci.yml
```

Look for:
- New or renamed steps
- Updated action versions (`actions/checkout`, `actions/cache`, `Homebrew/actions/setup-homebrew`)
- New `brew` subcommands used in CI steps
- Changed `if:` conditions
- Environment variable changes

### Step 3: Apply the fix

Typical fixes to pull from the official CI:
- **Bump action versions** — copy the updated `uses:` line (or the pinned SHA)
- **Add a missing step** — e.g. if `brew fetch` was added upstream and resolves a flaky audit
- **Update `brew generate-cask-ci-matrix` flags** — Homebrew sometimes changes the CLI interface
- **Fix `readall` / `audit` ordering** — the official CI refines `if:` conditions over time
- **Add `brew test-bot --cleanup`** if CI runners are getting polluted state

### Step 4: Validate

After updating `ci.yml`, open a PR with only the CI change. The CI itself will run on the PR and verify it works.

---

## Common failure patterns and fixes

### `brew readall` fails — "no such file to load"
Usually means a Homebrew internal library path changed. Check the official CI for how it sets up `setup-homebrew` and whether `core: true/false` or `cask: true/false` changed.

### `brew audit` times out or fails on URL
The cask's download URL may be stale or the audit now requires a live fetch. The official CI added a `brew fetch --cask` step before audit. Add it:
```yaml
- name: Run brew fetch --cask ${{ matrix.cask.token }}
  id: fetch
  run: |
    brew fetch --cask --retry --force ${{ join(matrix.fetch_args, ' ') }} '${{ matrix.cask.path }}'
  timeout-minutes: 30
  if: always() && matrix.cask
```

### `brew style` fails
A RuboCop style rule changed upstream. Run locally:
```bash
brew style Casks/dotnet-sdk8-0-400.rb
```
Fix the flagged offences. Common issues: trailing whitespace, missing frozen string literal, quote style.

### `Gather cask information` Ruby eval fails
The `brew ruby` inline script references a Homebrew internal that was renamed or removed. Compare the `Gather cask information` step with the official CI and update the Ruby code to match.

### `conclusion` job fails even when `test` passes
This is a known pattern — check the exact `run:` expression. The current form `run: ${{ needs.test.result == 'success' }}` evaluates to `true` or `false` as a shell command, which may fail in some shell versions. The fix is to use:
```yaml
- name: Result
  run: |
    if [[ "${{ needs.test.result }}" == "success" ]]; then exit 0; else exit 1; fi
```

### `generate-matrix` fails on ubuntu-latest
The official CI moved `generate-matrix` to `macos-latest` because `brew generate-cask-ci-matrix` may require macOS tooling. If this step starts failing, try switching `generate-matrix` runner to `macos-latest` to match the official CI.

---

## Quick reference: Key URLs

| Resource | URL |
|---|---|
| This repo's CI | `https://github.com/isen-ng/homebrew-dotnet-sdk-versions/blob/master/.github/workflows/ci.yml` |
| **Official Homebrew cask CI (reference)** | `https://github.com/Homebrew/homebrew-cask/blob/main/.github/workflows/ci.yml` |
| CI run history | `https://github.com/isen-ng/homebrew-dotnet-sdk-versions/actions/workflows/ci.yml` |
| setup-homebrew action | `https://github.com/Homebrew/actions/tree/main/setup-homebrew` |

---

## Rules for editing ci.yml

- **Always compare with the official CI before making changes** — do not try to fix CI in isolation without checking the upstream reference
- Keep the `brew tap isen-ng/dotnet-sdk-versions` step that appears after `setup-homebrew` in the `test` job — this is unique to this tap and must not be removed
- Do not add `workflow_dispatch` without also checking whether `generate-matrix` needs to run on macOS for it to work
- Keep `HOMEBREW_NO_INSTALL_FROM_API: 1` — removing it may cause `brew` to skip local tap files and fetch from the API instead, breaking tap-local cask testing
