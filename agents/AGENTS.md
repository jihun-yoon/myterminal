# Global Agent Instructions

## Engineering

- Reproduce bugs before modifying code when practical.
- Prefer root-cause fixes over symptom patches.
- Keep changes narrowly scoped.
- Avoid unnecessary dependencies.
- Preserve user changes and unrelated worktree edits.

## Verification

- Run relevant tests after changes.
- Do not claim success without verification.
- Treat flaky tests as failures that require investigation.
- Review the final diff before completing work.

## Git

- Do not modify generated files manually.
- Do not commit, push, or open a pull request unless explicitly requested.
- Do not use destructive Git commands without explicit approval.

## Safety

- Never expose secrets or modify credentials.
- Ask before destructive system operations.
- Prefer reversible operations and dry-runs when available.
