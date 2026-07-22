if not status is-interactive && test "$CI" != true
    exit
end

starship init fish | source
