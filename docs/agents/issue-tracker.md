# Issue tracker: Local Markdown

Issues and PRDs for this repo live as markdown files in `.scratch/`（**不纳入 git**；每人本地维护，见仓库根 `.gitignore`）。

## Conventions

- One feature per directory: `.scratch/<feature-slug>/`
- The PRD is `.scratch/<feature-slug>/PRD.md`
- Implementation issues are `.scratch/<feature-slug>/issues/<NN>-<slug>.md`, numbered from `01`
- Triage state is recorded as a `Status:` line near the top of each issue file (see `triage-labels.md` for the role strings)
- Category is recorded as `Category:` (`bug` or `enhancement`)
- Use `Status: done` when the slice is implemented and verified; agents should not pick these up
- Comments and conversation history append to the bottom of the file under a `## Comments` heading

## 已完成的工作（`Status: done`）

Matt Pocock 系 skill **不要求**删除已完成的 issue；`Status: done` 即表示 agent 不应再领取。

当某个 feature 目录下**全部** issue 均为 `done` 时，可以**本地删除**对应 `.scratch/<feature>/` 以减负——该目录本就不纳入 git（见根 `.gitignore`）。删除前请确认：

1. 仍需保留的决策已写入 **`docs/adr/`** 或 **`CONTEXT.md`**（勿只留在 issue 里）。
2. 仓库内 **`README.md` / `docs/`** 不再把 `.scratch/...` 当作「待办」引用。

需要留档时，可归档到个人笔记，或在 ADR 的「相关」段简要记录已完成切片，而不必长期维护完整 issue 树。

## When a skill says "publish to the issue tracker"

Create a new file under `.scratch/<feature-slug>/` (creating the directory if needed).

## When a skill says "fetch the relevant ticket"

Read the file at the referenced path. The user will normally pass the path or the issue number directly.

## Cancelled / out-of-scope features

Do not add a repo-root `.out-of-scope/` directory. When a feature is cancelled after triage:

1. Record the decision in **`docs/adr/`** (brief ADR: what was proposed, why not doing, alternatives).
2. Link the ADR from the related `.scratch/.../issues/*.md` issue (e.g. under **Cancelled** or **Comments**).
3. Mark the issue `Status: done` or `wontfix` as appropriate; do not leave orphan notes only in a side folder.
