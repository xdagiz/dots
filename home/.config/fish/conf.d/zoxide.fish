if not status is-interactive && test "$CI" != true
    return
end

zoxide init --cmd cd fish | source
