if not status is-interactive && test "$CI" != true
    exit
end

atuin init fish | source
