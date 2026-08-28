# dotfiles

A terminal-first macOS development environment built around Homebrew, GNU Stow,
mise, and a single version-controlled source of truth.

Cloning this repository changes nothing on the machine. The installer is a dry-run
by default and refuses to overwrite existing files or unrelated symlinks.

처음 사용하는 개발자는 먼저 [한국어 개발환경 설계 가이드](docs/design-guide.ko.md)를
읽어 각 도구의 역할, 안전한 적용 순서, 기존 설정과 충돌할 때의 대응 방법을
확인하세요.

## What is managed

- Terminal and shell: Ghostty, zsh, Starship, zoxide, fzf, Atuin
- Workspaces: tmux for general/remote work, Herdr for agent-heavy work
- CLI: ripgrep, fd, bat, eza, jq, delta, GitHub CLI
- Runtimes: mise with Node 24; uv for Python projects; pnpm for JavaScript
- Review editor: Neovim with Gitsigns, Neogit, Snacks, and which-key
- Agents: publisher-native Claude Code and Codex CLI, plus one global policy
- GUI editor: Zed (replace it with `visual-studio-code` in `Brewfile` if preferred)

## Repository layout

```text
.
├── Brewfile                 package inventory
├── install.sh               safe bootstrap entry point
├── AGENTS.md                instructions for this repository
├── agents/AGENTS.md         canonical global agent policy
├── scripts/
│   ├── bootstrap.sh         dry-run/apply implementation
│   ├── agents.sh            publisher-native agent CLI management
│   ├── check.sh             isolated installer verification
│   └── macos.sh             optional macOS defaults, dry-run by default
├── ghostty/                 Stow packages mirror the home directory
├── zsh/
├── starship/
├── atuin/
├── tmux/
├── herdr/
├── mise/
├── nvim/
└── git/
```

## Preview first

GNU Stow must already be available for the preview:

```bash
brew install stow
./install.sh
```

The command reports prospective links and conflicts but makes no changes. Package
status can also be checked without installing anything:

```bash
./install.sh --packages
```

## Apply explicitly

After reviewing the dry-run:

```bash
./install.sh --apply
```

To install the Brewfile packages and then create links:

```bash
./install.sh --apply --packages
```

The installer deliberately does not use `stow --adopt`. If `~/.zshrc` or another
target already exists, it stops and leaves that file untouched. Compare the files,
move the existing one to a backup location yourself, and run the preview again.

Optional macOS defaults are independent and opt-in:

```bash
./scripts/macos.sh
./scripts/macos.sh --apply
```

## Native agent CLIs

Claude Code and Codex are deliberately not installed by `Brewfile`. Their publishers'
native installers place launchers under `~/.local/bin`, which `.zprofile` adds to PATH.
The tracked manager is read-only by default:

```bash
./scripts/agents.sh status
./scripts/agents.sh install
```

After reviewing the preview, install both CLIs explicitly:

```bash
./scripts/agents.sh install --apply
```

Claude defaults to its stable channel and then uses its native updater. Codex defaults
to its latest release and updates by rerunning OpenAI's standalone installer:

```bash
./scripts/agents.sh update
./scripts/agents.sh update --apply
```

Override these defaults for a single operation with `CLAUDE_CHANNEL` or
`CODEX_RELEASE`. Do not install the same CLI through Homebrew or npm as well; the
manager stops when PATH points to a conflicting installation.

Official setup references:

- https://code.claude.com/docs/en/setup
- https://learn.chatgpt.com/docs/codex/cli

## Agent instruction layering

`agents/AGENTS.md` is the canonical global policy. The installer links it to:

```text
~/.codex/AGENTS.md
~/.claude/CLAUDE.md
```

Codex loads the global file first, followed by project-level `AGENTS.md` files from
the repository root toward the working directory. Keep project commands,
architecture, and domain rules in each project's committed `AGENTS.md`; keep
vendor-specific exceptions small and local.

Official Codex reference:
https://developers.openai.com/codex/guides/agents-md/

## Daily use

Use `t` for tmux and `h` for Herdr. They are intentionally peers rather than a
default nested stack. tmux uses `Ctrl-a`; Herdr keeps its default `Ctrl-b` prefix.

In Neovim:

- `<leader><space>` finds files and `<leader>/` searches text.
- `<leader>gg` opens Neogit.
- `]h` / `[h` move between changed hunks.
- `<leader>hp`, `<leader>hs`, and `<leader>hr` preview, stage, and reset a hunk.

## Verify the method

The check runs in an isolated temporary home directory:

```bash
./scripts/check.sh
```

It validates shell syntax, dry-run behavior, first application, idempotency, and
the expected agent adapter links without touching the real home directory.
