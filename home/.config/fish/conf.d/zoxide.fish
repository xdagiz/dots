if not status is-interactive && test "$CI" != true
    exit
end

zoxide init --cmd cd fish | source
