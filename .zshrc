alias g='git'
alias ga='git add'
alias gc='git commit -m'
alias gco='git checkout'
alias gs='git status -sb'
alias gss='git status'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias clr='clear'
alias zshrc="source ~/.zshrc"
alias bat="batcat"
alias ls="eza --icons"
alias tree="eza --tree"

alias vim='NVIM_APPNAME=nvim-lazyvim nvim'
alias v="nvim"

mkcd() {
  mkdir -p "$1" && cd "$1"
}

extract() {
  if [ -f "$1" ]; then
    case "$1" in
    *.tar.bz2) tar -xjf "$1" ;;
    *.tar.gz) tar -xzf "$1" ;;
    *.bz2) bunzip2 "$1" ;;
    *.rar) unrar -x "$1" ;;
    *.gz) gunzip "$1" ;;
    *.tar) tar -xf "$1" ;;
    *.tbz2) tar -xjf "$1" ;;
    *.tgz) tar -xzf "$1" ;;
    *.zip) unzip "$1" ;;
    *.7z) 7z -x "$1" ;;
    *) echo "'$1' cannot be extracted" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

adbpush() {
  adb.exe push $1 $2 $3 $4 $5 $6 $SDPATH
}

bindkey "^ " autosuggest-accept
bindkey '^H' backward-kill-word
bindkey "^p" history-search-backward
bindkey "^n" history-search-forward
# bindkey -v

## Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit
## End of Zinit's installer chunk

# Zoxide
eval "$(zoxide init --cmd cd zsh)"

# pnpm
export PNPM_HOME="/home/xdagiz/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls $realpath'
# --color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8 \
# --height 40% --tmux center --layout reverse
export FZF_DEFAULT_OPTS="\
--height 40% --layout reverse
--color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC \
--color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 \
--color=selected-bg:#45475A \
--color=border:#6C7086,label:#CDD6F4"

# Turso
export PATH="$PATH:/home/xdagiz/.turso"

export SDPATH="/storage/AAEE-1306"
export DEBUG='grammy*'
eval "$(atuin init zsh --disable-up-arrow)"

# . "$HOME/.atuin/bin/env"
eval "$(starship init zsh)"

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-completions
zinit light zdharma-continuum/fast-syntax-highlighting
