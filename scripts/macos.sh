#!/usr/bin/env bash
set -Eeuo pipefail

mode="dry-run"
[[ "${1:-}" == "--apply" ]] && mode="apply"

settings=(
  'Finder: show filename extensions'
  'Finder: show hidden files'
  'Keyboard: enable fast key repeat'
)

printf 'Proposed macOS settings:\n'
printf '  - %s\n' "${settings[@]}"

if [[ "${mode}" != "apply" ]]; then
  printf '\nNo changes were made. Run scripts/macos.sh --apply to opt in.\n'
  exit 0
fi

defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

printf '\nSettings applied. Restart Finder and affected apps when convenient.\n'
