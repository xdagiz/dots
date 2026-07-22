fish_add_path $HOME/.local/bin
fish_add_path $HOME/go/bin
fish_add_path $HOME/.turso

set -gx SDPATH /storage/AAEE-1306
set -gx EDITOR nvim
set -gx DEBUG 'grammy*'
set -gx STARSHIP_LOG error
set -gx ATUIN_NOBIND true
set -gx TERMINFO ~/.terminfo

set -U fish_greeting

set -gx FZF_DEFAULT_OPTS \
    '--height 40% --layout reverse' \
    '--tmux center,60%,50%' \
    '--color=fg:#B4BEFE,header:#F38BA8,info:#EBA0AC,pointer:#F5E0DC' \
    '--color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8' \
    '--color=selected-bg:#45475A' \
    '--color=border:#6C7086,label:#CDD6F4'

if status is-interactive
    ulimit -c 0

    fastfetch -c examples/28

    fish_vi_key_bindings
    set -g fish_cursor_default block
    set -g fish_cursor_insert block
    set -g fish_cursor_replace_one underscore
    set -g fish_cursor_visual block

    # fzf_configure_bindings --directory=\ct --variables=\e\cv
    bind -M insert \ct tv
    bind -M insert ctrl-o "commandline -r 'cdi'; commandline -f execute"

    source "/home/xdagiz/.config/fish/secrets.fish"
    source "/home/xdagiz/.config/fish/functions.fish"

    function fish_user_key_bindings
        bind -M insert \cf accept-autosuggestion
        bind -M insert \cp history-search-backward
        bind -M insert \cn history-search-forward
        bind -M insert \cr _atuin_search
    end
end

# Pi
fish_add_path "/home/xdagiz/.local/share/fnm/node-versions/v22.22.2/installation/bin"

# nub
set -gx PATH $HOME/.nub/bin $PATH

# pnpm
set -gx PNPM_HOME "/home/xdagiz/.local/share/pnpm"
if not string match -q -- "$PNPM_HOME/bin" $PATH
  set -gx PATH "$PNPM_HOME/bin" $PATH
end
# pnpm end
