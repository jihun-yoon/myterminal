#!/usr/bin/env bash
set -Eeuo pipefail

repo_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
fixture_home="$(mktemp -d)"
conflict_home="$(mktemp -d)"
trap 'rm -rf -- "${fixture_home}" "${conflict_home}"' EXIT

bash -n \
  "${repo_dir}/install.sh" \
  "${repo_dir}/scripts/agents.sh" \
  "${repo_dir}/scripts/bootstrap.sh" \
  "${repo_dir}/scripts/macos.sh"
HOME="${fixture_home}" PATH="/usr/bin:/bin" "${repo_dir}/scripts/agents.sh" status
HOME="${fixture_home}" PATH="/usr/bin:/bin" "${repo_dir}/scripts/agents.sh" install
[[ ! -e "${fixture_home}/.local/bin/claude" ]]
[[ ! -e "${fixture_home}/.local/bin/codex" ]]

mkdir -p "${conflict_home}/bin"
touch "${conflict_home}/bin/claude"
chmod +x "${conflict_home}/bin/claude"
if HOME="${conflict_home}" PATH="${conflict_home}/bin:/usr/bin:/bin" \
  "${repo_dir}/scripts/agents.sh" install >/dev/null 2>&1; then
  printf 'Expected a conflicting agent installation to be rejected.\n' >&2
  exit 1
fi

"${repo_dir}/install.sh" --target "${fixture_home}"
"${repo_dir}/install.sh" --target "${fixture_home}" --apply
"${repo_dir}/install.sh" --target "${fixture_home}"

for target in \
  "${fixture_home}/.config/ghostty/config" \
  "${fixture_home}/.config/nvim/init.lua"; do
  [[ -e "${target}" ]] || {
    printf 'Expected managed file missing: %s\n' "${target}" >&2
    exit 1
  }
done

for target in \
  "${fixture_home}/.codex/AGENTS.md" \
  "${fixture_home}/.claude/CLAUDE.md"; do
  [[ -L "${target}" ]] || {
    printf 'Expected agent adapter symlink missing: %s\n' "${target}" >&2
    exit 1
  }
done

touch "${conflict_home}/.zshrc"
if "${repo_dir}/install.sh" --target "${conflict_home}" >/dev/null 2>&1; then
  printf 'Expected an existing-file conflict, but the dry-run succeeded.\n' >&2
  exit 1
fi

printf 'All bootstrap checks passed.\n'
