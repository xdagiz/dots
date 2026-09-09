if not status is-interactive && test "$CI" != true
    return
end

set -gx ATUIN_NOBIND true
atuin init fish | source
