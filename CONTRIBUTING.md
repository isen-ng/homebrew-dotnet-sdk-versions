# Contribution guide

## Official cask

If there is a need to refer to the official cask, [it can be found here](https://github.com/Homebrew/homebrew-cask/blob/main/Casks/d/dotnet-sdk.rb).

## Continuous Integration reference

`.github/workflows/ci.yml` is referenced from the [official cask CI](https://github.com/Homebrew/homebrew-cask/blob/master/.github/workflows/ci.yml).
If CI is broken, there is a good chance that we can find updates from the official cask CI that fixes our CI.

## Automatic updates

Four scheduled Github Actions workflows keep the casks and `README.md` up to date. They run daily in
this order (times in UTC):

| Time  | Workflow              | Script                   |
|-------|-----------------------|--------------------------|
| 22:17 | `auto-updater`        | `auto_updater.py`        |
| 23:47 | `auto-committer`      | `auto_committer.py`      |
| 00:17 | `auto-meta-updater`   | `auto_meta_updater.py`   |
| 01:47 | `auto-committer`      | `auto_committer.py`      |
| 02:17 | `auto-readme-updater` | `auto_readme_updater.py` |
| 03:47 | `auto-committer`      | `auto_committer.py`      |

`auto_updater.py` enumerates over each cask, searches through the releases in their respective
`releases.json` and authors a pull request if there is a newer version released. A cask that already
has an open pull request for that version is skipped. When a newer version supersedes an open pull
request, the old pull request is closed. If one cask fails, the others are still processed and the
run fails at the end so the author is notified. Each `releases.json` is downloaded once per run from
`https://builds.dotnet.microsoft.com/dotnet/release-metadata/<major>.<minor>/releases.json`. Update pull
requests only change their cask file, so they never conflict with each other.

All the releases and their notes are published [here](https://github.com/dotnet/core/tree/main/release-notes).

`auto_meta_updater.py` points each meta cask (e.g. `dotnet-sdk8`) at its newest feature band cask
and opens or refreshes the `update-meta-casks` pull request.

`auto_readme_updater.py` sets the .NET SDK version of every row in `README.md` (meta, versions and
preview tables) to the version in its cask, and opens or refreshes the `update-readme` pull request. It is
the only script that edits `README.md`, which keeps the version tables free of merge conflicts. A cask
without a README row is reported in the log; add its row by hand.

## Automatic commits

`auto_committer.py` combs through the open `[Auto]` pull requests, checks their status, and if
they are mergeable and the `conclusion` check passed, (squash and) merges them. Pull requests with
conflicts, failed checks or merge errors require manual intervention from the author. In this case,
the author will be notified via a failed run.

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

This repo's AI skills live in `.agents/skills/`, the shared folder from the
[Agent Skills](https://agentskills.io) standard. Factory Droid, Cursor, Windsurf (Devin Local), Codex,
GitHub Copilot and Gemini CLI all read it directly. Claude Code only reads `.claude/skills/`, so
`.claude/skills` is a committed symlink to `../.agents/skills`.

The skills currently available are:

| Skill | Purpose |
|---|---|
| `new-cask` | Adding a new dotnet-sdk cask or feature band |
| `update-cask` | Manually updating an existing cask to a newer version |
| `fix-ci` | Investigating and fixing CI failures |

### Adding a new skill

Create a new folder under `.agents/skills/` containing a `SKILL.md` file with YAML frontmatter:

```
.agents/skills/
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

No other step is needed: every supported agent, including Claude Code through the symlink, picks it up.

### Adding support for a new AI agent

Most agents read `.agents/skills/` already. If one only reads its own folder, add a single directory
symlink for it, the same way `.claude/skills` is set up:

```
mkdir -p .newagent
ln -s ../.agents/skills .newagent/skills
git add .newagent/skills
```

Windows contributors need `git config core.symlinks true` (and symlink permission) for the symlink to
be checked out as a link.
