if not status is-interactive && test "$CI" != true
    return
end

starship init fish | source
