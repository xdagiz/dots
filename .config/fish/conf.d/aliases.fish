if not status is-interactive && test "$CI" != true
    exit
end

abbr -a jjcm --set-cursor "jj commit -m '%'"
abbr -a jjdm --set-cursor "jj describe -m '%'"
abbr -a jjcmi 'jj commit -i'
abbr -a jjdi 'jj describe -i'
abbr -a jjbmc --set-cursor 'jj bookmark create %'
abbr -a jjrebm 'jj rebase -r@ --onto main'
alias g git
alias ga 'git add'
abbr -a gcm --set-cursor "git commit -m '%'"
alias gca 'git commit --amend'
alias gco 'git checkout'
alias gss 'git status'
alias gl 'git log --oneline --graph --decorate'
alias gp 'git push'
abbr -a gc1 'git clone --depth 1'
abbr -a ghrps --set-cursor "gh repo sync xdagiz/% && jj git fetch"
abbr -a c cargo
abbr -a cr 'cargo run'
abbr -a cb 'cargo build'
abbr -a ct 'cargo test'
abbr -a cw 'cargo watch -x run'
abbr -a ccl 'cargo clippy'
abbr -a gr 'go run ./...'
abbr -a gb 'go build ./... -o'
abbr -a gt 'go test ./...'
abbr -a rmrf  'rm -rf'
abbr -a fishrc 'source ~/.config/fish/config.fish'
abbr -a mkdirp 'mkdir -p'
abbr -a -p anywhere L '| less'
abbr -a -p anywhere G --set-cursor "| grep '%'"
abbr -a -p anywhere C '| wc -l'
abbr -a n "nub"
abbr -a nr "nub run"
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
alias adbsh 'adb shell'
alias scr1 'scrcpy --video-codec=h264 --video-encoder=OMX.google.h264.encoder -s 420389bdda3b3100'
alias scr2 'scrcpy -s R8YY835C22N --no-audio'
set -l _qemu 'qemu-x86_64 -cpu max'
alias bun "$_qemu $(which bun)"
alias bunx "$_qemu $(which bunx)"
alias opencode "$_qemu $(which opencode)"
alias oc "$_qemu $(which opencode)"
alias kilo "$_qemu $(which kilo)"
alias course-sdk "$_qemu $(which course-sdk)"
alias coderabbit "$_qemu $(which coderabbit)"
alias scc "scc -c --no-cocomo --no-size"
