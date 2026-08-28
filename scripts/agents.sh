#!/usr/bin/env bash
set -Eeuo pipefail

action="status"
action_set="false"
mode="dry-run"
claude_channel="${CLAUDE_CHANNEL:-stable}"
codex_release="${CODEX_RELEASE:-latest}"
installer_dir=""

usage() {
  cat <<'USAGE'
Usage: ./scripts/agents.sh [status|install|update] [--apply]

Manage publisher-native Claude Code and Codex installations.

Actions:
  status       Show the active command paths and versions (default).
  install      Install either native CLI when it is missing.
  update       Update existing native installations.

Options:
  --apply      Execute installers or updates. Otherwise, only preview them.
  -h, --help   Show this help.

Environment:
  CLAUDE_CHANNEL  Claude release channel or version (default: stable).
  CODEX_RELEASE   Codex release or version (default: latest).

Examples:
  ./scripts/agents.sh status
  ./scripts/agents.sh install
  ./scripts/agents.sh install --apply
  CLAUDE_CHANNEL=latest ./scripts/agents.sh install --apply
USAGE
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

cleanup() {
  [[ -n "${installer_dir}" && -d "${installer_dir}" ]] || return 0
  rm -rf -- "${installer_dir}"
}
trap cleanup EXIT

for argument in "$@"; do
  case "${argument}" in
    status|install|update)
      [[ "${action_set}" == "false" ]] || die "only one action may be specified"
      action="${argument}"
      action_set="true"
      ;;
    --apply)
      mode="apply"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown argument: ${argument}"
      ;;
  esac
done

if [[ ! "${claude_channel}" =~ ^(stable|latest|[0-9]+\.[0-9]+\.[0-9]+(-[^[:space:]]+)?)$ ]]; then
  die "invalid CLAUDE_CHANNEL: ${claude_channel}"
fi

if [[ ! "${codex_release}" =~ ^(latest|[0-9]+\.[0-9]+\.[0-9]+(-alpha(\.[0-9]+){0,2}|-beta(\.[0-9]+)?)?)$ ]]; then
  die "invalid CODEX_RELEASE: ${codex_release}"
fi

native_launcher() {
  printf '%s/.local/bin/%s' "${HOME}" "$1"
}

active_command() {
  command -v "$1" 2>/dev/null || true
}

show_agent_status() {
  local name="$1"
  local launcher
  local active
  launcher="$(native_launcher "${name}")"
  active="$(active_command "${name}")"

  printf '%s\n' "${name}:"
  if [[ -x "${launcher}" ]]; then
    printf '  native launcher: %s\n' "${launcher}"
    printf '  version: %s\n' "$("${launcher}" --version 2>&1 | head -n 1)"
  else
    printf '  native launcher: not installed\n'
  fi

  if [[ -n "${active}" ]]; then
    printf '  active command: %s\n' "${active}"
    if [[ "${active}" != "${launcher}" ]]; then
      printf '  warning: PATH selects a non-native installation\n'
    fi
  else
    printf '  active command: not found on PATH\n'
  fi
}

assert_no_conflicting_installation() {
  local name="$1"
  local launcher
  local active
  launcher="$(native_launcher "${name}")"
  active="$(active_command "${name}")"

  if [[ ! -x "${launcher}" && -n "${active}" ]]; then
    die "${name} already resolves to a non-native installation: ${active}"
  fi

  if [[ -x "${launcher}" && -n "${active}" && "${active}" != "${launcher}" ]]; then
    die "${name} native launcher exists, but PATH selects: ${active}"
  fi
}

ensure_installer_dir() {
  if [[ -z "${installer_dir}" ]]; then
    installer_dir="$(mktemp -d)"
  fi
}

run_official_installer() {
  local name="$1"
  local url="$2"
  local shell_name="$3"
  shift 3

  command -v curl >/dev/null 2>&1 || die "curl is required to install ${name}"
  ensure_installer_dir

  local installer_path="${installer_dir}/${name}-install.sh"
  printf 'Downloading official %s installer from %s\n' "${name}" "${url}"
  curl -fsSL "${url}" -o "${installer_path}"
  "${shell_name}" "${installer_path}" "$@"
}

install_agents() {
  local claude_launcher
  local codex_launcher
  claude_launcher="$(native_launcher claude)"
  codex_launcher="$(native_launcher codex)"

  assert_no_conflicting_installation claude
  assert_no_conflicting_installation codex

  if [[ -x "${claude_launcher}" ]]; then
    printf 'Claude Code is already installed natively; leaving it unchanged.\n'
  elif [[ "${mode}" == "dry-run" ]]; then
    printf 'Would install Claude Code from https://claude.ai/install.sh (channel: %s).\n' "${claude_channel}"
  else
    run_official_installer claude https://claude.ai/install.sh bash "${claude_channel}"
  fi

  if [[ -x "${codex_launcher}" ]]; then
    printf 'Codex is already installed natively; leaving it unchanged.\n'
  elif [[ "${mode}" == "dry-run" ]]; then
    printf 'Would install Codex from https://chatgpt.com/codex/install.sh (release: %s).\n' "${codex_release}"
  else
    CODEX_NON_INTERACTIVE=true CODEX_RELEASE="${codex_release}" \
      run_official_installer codex https://chatgpt.com/codex/install.sh sh
  fi
}

update_agents() {
  local claude_launcher
  local codex_launcher
  claude_launcher="$(native_launcher claude)"
  codex_launcher="$(native_launcher codex)"

  assert_no_conflicting_installation claude
  assert_no_conflicting_installation codex

  [[ -x "${claude_launcher}" ]] || die "Claude Code is not installed natively; run the install action first"
  [[ -x "${codex_launcher}" ]] || die "Codex is not installed natively; run the install action first"

  if [[ "${mode}" == "dry-run" ]]; then
    printf 'Would run the Claude Code native updater.\n'
    printf 'Would rerun the Codex standalone installer (release: %s).\n' "${codex_release}"
    return
  fi

  "${claude_launcher}" update
  CODEX_NON_INTERACTIVE=true CODEX_RELEASE="${codex_release}" \
    run_official_installer codex https://chatgpt.com/codex/install.sh sh
}

case "${action}" in
  status)
    show_agent_status claude
    show_agent_status codex
    ;;
  install)
    install_agents
    [[ "${mode}" == "apply" ]] || printf '\nNo changes were made. Add --apply to install.\n'
    ;;
  update)
    update_agents
    [[ "${mode}" == "apply" ]] || printf '\nNo changes were made. Add --apply to update.\n'
    ;;
esac
