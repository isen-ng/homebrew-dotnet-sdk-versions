## AI Skills Symlink Architecture
- This project uses a master `.aiskills/` directory.
- All AI agents (.claude, .windsurf, .cursor, .agents, .factory) MUST have symlinks to these skills.
- If a PR adds a new skill to `.aiskills/`, the contributor MUST run `./sym-link-aiskills.sh`.
- **Reviewer Task**: If you see new files in `.aiskills/` but no corresponding symlink updates in the agent folders, flag this as a required change.
