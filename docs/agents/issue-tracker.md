# Issue tracker: GitHub

Issues and PRDs for this repo live as GitHub issues on `Zoti321/comic-book-maker`. Use the `gh` CLI for all operations.

## Conventions

- **Create an issue**: `gh issue create --title "..." --body "..."`. Use a heredoc for multi-line bodies.
- **Read an issue**: `gh issue view <number> --comments`
- **List issues**: `gh issue list --state open --json number,title,body,labels,comments`
- **Comment on an issue**: `gh issue comment <number> --body "..."`
- **Close**: `gh issue close <number> --comment "..."`

Infer the repo from `git remote -v` — `gh` does this automatically when run inside a clone.

## Labels

This repo does **not** use Matt Pocock triage labels (`needs-triage`, `ready-for-agent`, etc.). When a skill says to apply a triage label, **skip it** — do not create labels or call `gh issue edit --add-label` unless the user explicitly asks.

You may use GitHub's built-in `bug` / `enhancement` labels for category if helpful; they are optional.

## PRD vs implementation issues

- **PRD**: one GitHub issue with a title like `[PRD] <feature name>` and the full PRD in the body.
- **Implementation slices**: separate issues; reference the parent PRD issue number in the body under `## Parent`.

## When a skill says "publish to the issue tracker"

Create a GitHub issue (no triage labels unless the user requests them).

## When a skill says "fetch the relevant ticket"

Run `gh issue view <number> --comments`.

## Cancelled / out-of-scope features

1. Record the decision in **`docs/adr/`** (brief ADR: what was proposed, why not doing, alternatives).
2. Link the ADR from the GitHub issue (comment or body update).
3. Close the issue with a short comment explaining why.
