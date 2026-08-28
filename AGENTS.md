# Dotfiles Repository Instructions

## Scope

- This repository defines a reproducible setup; do not apply it to the real home
  directory unless the user explicitly asks.
- Do not use `stow --adopt` or overwrite an existing home-directory file.
- Keep user identity, credentials, tokens, and machine-specific secrets out of Git.

## Structure

- Keep Homebrew-managed packages in `Brewfile`.
- Keep Claude Code and Codex publisher-managed through `scripts/agents.sh`.
- Keep each Stow package shaped like its destination under the home directory.
- Keep global cross-agent policy canonical in `agents/AGENTS.md`.
- Keep project-specific instructions in the project root, as this file does.

## Verification

- Run `bash -n install.sh scripts/*.sh` after shell changes.
- Run `./scripts/check.sh` when GNU Stow is available.
- Use `./install.sh --target <temporary-directory>` for manual bootstrap checks.
- Review `git diff --check` before completing changes.
