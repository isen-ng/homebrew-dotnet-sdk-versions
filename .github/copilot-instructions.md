## AI Skills Layout
- AI skills live in `.agents/skills/<skill-name>/SKILL.md` (the Agent Skills standard folder).
- `.claude/skills` is a committed symlink to `../.agents/skills`; do not replace it with a real folder or per-skill copies.
- **Reviewer Task**: Flag PRs that add skills anywhere other than `.agents/skills/`, or that add per-agent copies of skills (e.g. `.cursor/skills/`, `.factory/skills/`, `.windsurf/skills/`).
