# Contribution guide

## Official cask

If there is a need to refer to the official cask, [it can be found here](https://github.com/Homebrew/homebrew-cask/blob/main/Casks/d/dotnet-sdk.rb).

## Continuous Integration reference

`.github/workflows/ci.yml` is referenced from the [official cask CI](https://github.com/Homebrew/homebrew-cask/blob/master/.github/workflows/ci.yml).
If CI is broken, there is a good chance that we can find updates from the official cask CI that fixes our CI.

## Automatic updates

Each working cask will be updated weekly automatically by running `auto_updater.py` through a
Github Actions scheduled workflow.

The script will enumerate over each cask, search through the releases in their respective
`releases.json` and author a pull request if there is a newer version released.

All the releases and their notes are published [here](https://github.com/dotnet/core/tree/main/release-notes).

## Automatic commits

Each day of the week, except the day that the auto updater is running, the `auto_committer.sh` script is ran
through a Github Actions scheduled workflow.

This script will comb through existing pull requests created by `auto-updater.sh`, check their status, and if
they are mergeable, (squash and) merge the commit. Only those with conflicts, or merge issues will require
manual intervention from the author. In this case, the author will be notified via a failed run.

## Adding a new cask

### With AI assistance (recommended)

This repo includes AI skills that guide your agent through the process. If you are using Claude Code,
Cursor, Windsurf, or another supported agent, it will automatically load the `new-cask` skill and
follow the correct steps when you ask it to add a new cask.

Example prompts:
- *"Add a new cask for dotnet-sdk12-0-100"*
- *"Add support for .NET 12 preview"*

The skill covers stub creation, running `auto_updater.py` in dry-run mode, validation, and opening
the PR correctly.

### Manually

Install the necessary tools if you already haven't:

```shell
./brew_install_necessary.sh
```

Use the existing casks as a template and fill in the version number till the patch major version. The filename and cask name must match, according to BrewCask's rules.

The runtime version, `sha256`, and the `url` isn't important and can be filled with placeholder text.

```ruby
cask 'dotnet-sdk-2.99.400' do
  version '2.99.400,2.0.0'
  sha256 '?????'

  url '???'

  ... so on and so forth ...

end
```

Then run `auto_updater.py` in dry run mode:

```shell
# passing in no arguments defaults to dry run mode
./auto_updater.py
```

The dry run mode will update all casks, including the cask you've just added without committing and publishing pull
requests.

Branch out, add the file you want to commit, commit, and push:

```shell
git checkout -b new-cask/dotnet-sdk-2.99.400
git add Casks/dotnet-sdk-2.99.400.rb
git commit -m "Add support for dotnet-sdk-2.99.400.rb"
git push origin new-cask/dotnet-sdk-2.99.400  # repo owner
git push fork new-cask/dotnet-sdk-2.99.400    # external contributor with a fork
```

## Fixing CI

### With AI assistance (recommended)

This repo includes an AI skill that knows the CI is modelled after the official Homebrew cask CI and
guides your agent to check the upstream reference before making any changes.

Example prompts:
- *"CI is broken, please fix it"*
- *"The brew audit step is failing, investigate and fix"*
- *"Sync our ci.yml with the latest official Homebrew cask CI"*

The skill will always fetch and compare against the [official cask CI](https://github.com/Homebrew/homebrew-cask/blob/master/.github/workflows/ci.yml)
before suggesting any changes.

### Manually

Check the [official cask CI](https://github.com/Homebrew/homebrew-cask/blob/master/.github/workflows/ci.yml)
for upstream fixes first, then apply the relevant changes to `.github/workflows/ci.yml`.

## How to upgrade a cask

```shell
brew update
brew upgrade --cask dotnet-sdk2-1-400
```

## Tapping a local path

```shell
brew tap isen-ng/dotnet-sdk-versions $PWD
```

## AI skills

This repo uses a set of AI skills stored in `.aiskills/` that are symlinked into the agent-specific
folders (`.claude/skills/`, `.windsurf/rules/`, `.cursor/rules/`, `.agents/skills/`, `.factory/skills/`).

The skills currently available are:

| Skill | Purpose |
|---|---|
| `new-cask` | Adding a new dotnet-sdk cask or feature band |
| `update-cask` | Manually updating an existing cask to a newer version |
| `fix-ci` | Investigating and fixing CI failures |

### Adding a new skill

1. Create a new folder under `.aiskills/` containing a `SKILL.md` file with YAML frontmatter:

```
.aiskills/
└── my-new-skill/
    └── SKILL.md
```

The `SKILL.md` must start with:

```yaml
---
name: my-new-skill
description: What this skill does and when to use it.
---
```

2. Run the sync script to propagate the new skill to all agent folders:

```
./sym-link-aiskills.sh
```

3. Commit both the new skill and the updated symlink folders:

```
git add .aiskills/my-new-skill
git add .claude/skills .windsurf/rules .cursor/rules .agents/skills .factory/skills
git commit -m "Add my-new-skill AI skill"
```

### Adding support for a new AI agent

If a new AI coding agent needs to be supported, add its skills folder path to the `TARGETS` array
in `sym-link-aiskills.sh`, then run the script and commit the results:

```bash
# In sym-link-aiskills.sh, add to the TARGETS array:
TARGETS=(
  ".claude/skills"
  ".windsurf/rules"
  ".cursor/rules"
  ".agents/skills"
  ".factory/skills"
  ".newagent/skills"   # ← add the new agent's folder here
)
```

Then:

```
./sym-link-aiskills.sh
git add .newagent/skills
git commit -m "Add AI skill support for newagent"
```
