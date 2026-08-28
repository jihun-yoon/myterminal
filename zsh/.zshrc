# Keep interactive-only setup out of scripts and non-interactive shells.
[[ -o interactive ]] || return

export EDITOR="nvim"
export VISUAL="$EDITOR"
export PAGER="less"
export LESS="-FRX"

setopt AUTO_CD
setopt HIST_IGNORE_DUPS
setopt SHARE_HISTORY

command -v mise >/dev/null 2>&1 && eval "$(mise activate zsh)"
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
command -v fzf >/dev/null 2>&1 && source <(fzf --zsh)
command -v atuin >/dev/null 2>&1 && eval "$(atuin init zsh)"
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"

alias t="tmux"
alias h="herdr"
alias v="nvim"
alias cat="bat"
alias ls="eza --group-directories-first"
alias ll="eza --long --all --group --git --group-directories-first"
alias tree="eza --tree --group-directories-first"
