# Issue tracker: Local Markdown

Issues and PRDs for this repo live as markdown files in `.scratch/`.

## Conventions

- One feature per directory: `.scratch/<feature-slug>/`
- The PRD is `.scratch/<feature-slug>/PRD.md`
- Implementation issues are `.scratch/<feature-slug>/issues/<NN>-<slug>.md`, numbered from `01`
- Triage state is recorded as a `Status:` line near the top of each issue file (see `triage-labels.md` for the role strings)
- Category is recorded as `Category:` (`bug` or `enhancement`)
- Use `Status: done` when the slice is implemented and verified; agents should not pick these up
- Comments and conversation history append to the bottom of the file under a `## Comments` heading

## When a skill says "publish to the issue tracker"

Create a new file under `.scratch/<feature-slug>/` (creating the directory if needed).

## When a skill says "fetch the relevant ticket"

Read the file at the referenced path. The user will normally pass the path or the issue number directly.

## Cancelled / out-of-scope features

Do not add a repo-root `.out-of-scope/` directory. When a feature is cancelled after triage:

1. Record the decision in **`docs/adr/`** (brief ADR: what was proposed, why not doing, alternatives).
2. Link the ADR from the related `.scratch/.../issues/*.md` issue (e.g. under **Cancelled** or **Comments**).
3. Mark the issue `Status: done` or `wontfix` as appropriate; do not leave orphan notes only in a side folder.
