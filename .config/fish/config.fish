fish_add_path $HOME/.go/bin
fish_add_path $HOME/.local/bin
fish_add_path $HOME/zig-linux-x86_64-0.13.0
fish_add_path $HOME/go/bin
fish_add_path $HOME/.turso
fish_add_path $PNPM_HOME
fish_add_path "$HOME/bun/bin"
fish_add_path "$HOME/.opencode/bin"

set -gx PNPM_HOME $HOME/.local/share/pnpm
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
    fastfetch -c examples/28

    starship init fish | source
    fzf --fish | source
    atuin init fish | source
    zoxide init --cmd cd fish | source

    fish_vi_key_bindings
    set -g fish_cursor_default block
    set -g fish_cursor_insert block
    set -g fish_cursor_replace_one underscore
    set -g fish_cursor_visual block

    # fzf_configure_bindings --directory=\ct --variables=\e\cv
    bind -M insert \ct tv

    function fish_user_key_bindings
        bind -M insert \cf accept-autosuggestion
        bind -M insert \cp history-search-backward
        bind -M insert \cn history-search-forward
        bind -M insert \cr _atuin_search
    end

    abbr -a jjcm --set-cursor "jj commit -m '%'"
    abbr -a jjdm --set-cursor "jj describe -m '%'"
    abbr -a jjcmi 'jj commit -i'
    abbr -a jjdi 'jj describe -i'
    abbr -a jjbmc --set-cursor 'jj bookmark create %'
    abbr -a g git
    abbr -a ga 'git add'
    abbr -a gaa 'git add --all'
    abbr -a gc 'git commit'
    abbr -a gcm --set-cursor "git commit -m '%'"
    abbr -a gca 'git commit --amend'
    abbr -a gco 'git checkout'
    abbr -a gs 'git status -sb'
    abbr -a gss 'git status'
    abbr -a gd 'git diff'
    abbr -a gds 'git diff --staged'
    abbr -a gl 'git log --oneline --graph --decorate'
    abbr -a gp 'git push'
    abbr -a --command git co checkout
    abbr -a --command git br branch
    abbr -a --command git sw switch
    abbr -a c cargo
    abbr -a cr 'cargo run'
    abbr -a cb 'cargo build'
    abbr -a ct 'cargo test'
    abbr -a cw 'cargo watch -x run'
    abbr -a ccl 'cargo clippy'
    abbr -a rmrf  'rm -rf'
    abbr -a fishrc 'source ~/.config/fish/config.fish'
    abbr -a mkdirp 'mkdir -p'
    abbr -a -p anywhere L '| less'
    abbr -a -p anywhere G --set-cursor "| grep '%'"
    abbr -a -p anywhere C '| wc -l'
    alias ... 'cd ../../'
    alias .... 'cd ../../../'
    alias clr 'clear'
    alias ls 'eza --icons --git'
    alias la 'eza --icons --git -a'
    alias ll 'eza --icons --git -l'
    alias lla 'eza --icons --git -la'
    alias tree 'eza --tree --icons'
    alias v nvim
    alias vim 'bob use v0.11.6 -n && NVIM_APPNAME=nvim-lazyvim nvim'
    alias vi /usr/bin/vim
    alias paru 'paru --bottomup'
    alias adbsh 'adb shell'
    alias scr1 'scrcpy --video-codec=h264 --video-encoder=OMX.google.h264.encoder -s 420389bdda3b3100'
    alias scr2 'scrcpy -s R8YY835C22N --no-audio'
    set -l _qemu 'qemu-x86_64-static -cpu max'
    alias bun "$_qemu $(which bun)"
    alias opencode "$_qemu $(which opencode)"
    alias oc "$_qemu $(which opencode)"
    alias kilo "$_qemu $(which kilo)"
    alias course-sdk "$_qemu $(which course-sdk)"

    function mkcd
        mkdir -p $argv[1]; and cd $argv[1]
    end

    function untar
        if not test -f $argv[1]
            echo "'$argv[1]' is not a valid file"
            return 1
        end
        switch $argv[1]
            case '*.tar.gz' '*.tgz'
                tar -xzf $argv[1]
            case '*.tar.bz2'
                tar -xjf $argv[1]
            case '*.tar.xz'
                tar -xJf $argv[1]
            case '*.tar'
                tar -xf $argv[1]
            case '*.gz'
                gunzip $argv[1]
            case '*.rar'
                unrar x $argv[1]
            case '*.zip'
                unzip $argv[1]
            case '*.7z'
                7z x $argv[1]
            case '*'
                echo "'$argv[1]' cannot be extracted (unknown format)"
                return 1
        end
    end

    function rmfzf --description 'Interactively select and delete files'
        set files (fd --max-depth 1 . --type file | fzf -m --preview 'bat --style=numbers --color=always --line-range :500 {}')
        if not set -q files[1]
            echo "No files selected."
            return
        end
        echo "Will delete:"
        for f in $files
            echo "  $f"
        end
        read -P "Confirm? [y/N]: " confirm
        if string match -qi 'y' $confirm
            rm $files
            echo "Deleted."
        else
            echo "Aborted."
        end
    end

    function adbpush
        adb push $argv $SDPATH
    end

    function port
        ss -tulpn | grep ":$argv[1]"
    end
end


