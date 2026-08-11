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

function cdf --description 'Interactively select and cd into a subdirectory'
    set -l dir (fd --max-depth 1 --type d --exclude '.git' | fzf --preview 'eza --tree --icons --level 2 --color=always {}')
    if test -n "$dir"
        cd $dir
    end
end

function port
    ss -tulpn | grep ":$argv[1]"
end
