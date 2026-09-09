fish_add_path $HOME/.local/bin
fish_add_path $HOME/go/bin
fish_add_path $HOME/.turso

set -gx SDPATH /storage/AAEE-1306
set -gx EDITOR nvim
set -gx STARSHIP_LOG error
set -gx TERMINFO ~/.terminfo
set -gx NODE_COMPILE_CACHE ~/.cache/pi-compile-cache

set -U fish_greeting
set -U __done_min_cmd_duration 5000
set -U __done_notify_sound 1

set -gx FZF_DEFAULT_OPTS \
    '--height 40% --layout reverse' \
    '--tmux center,80%,60%' \
    '--color=fg:#B4BEFE,header:#F38BA8,info:#EBA0AC,pointer:#F5E0DC' \
    '--color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8' \
    '--color=selected-bg:#45475A' \
    '--color=border:#6C7086,label:#CDD6F4'

if status is-interactive
    mise activate fish | source

    ulimit -c 0

    fastfetch -c examples/28

    fish_vi_key_bindings
    set -g fish_cursor_default block blink
    set -g fish_cursor_insert block blink
    set -g fish_cursor_replace_one underscore blink
    set -g fish_cursor_visual block blink

    bind -M insert \ca beginning-of-line
    bind -M insert \ce end-of-line
    # fzf_configure_bindings --directory=\ct --variables=\e\cv
    bind -M insert \ct tv
    bind -M insert ctrl-o "commandline -r 'cdi'; commandline -f execute"

    source "$HOME/.config/fish/secrets.fish"
    source "$HOME/.config/fish/functions.fish"

    function fish_user_key_bindings
        bind -M insert \cf accept-autosuggestion
        bind -M insert \cp history-search-backward
        bind -M insert \cn history-search-forward
        bind -M insert \cr _atuin_search
        bind -M insert ctrl-alt-w backward-kill-bigword
    end

    for _f in $HOME/.config/herdr/plugins/github/herdr-automatic-rename-*/shell/hook.fish
      test -r "$_f"; and source "$_f"; and break
    end
end

# nub
set -gx PATH $HOME/.nub/bin $PATH

# pnpm
set -gx PNPM_HOME "$HOME/.local/share/pnpm"
if not string match -q -- "$PNPM_HOME/bin" $PATH
  set -gx PATH "$PNPM_HOME/bin" $PATH
end
# pnpm end
