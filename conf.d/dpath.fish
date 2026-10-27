status is-interactive; or return

bind ctrl-backspace _dpath_kill 2>/dev/null
bind \b _dpath_kill

function _dpath_uninstall --on-event dpath_uninstall
    bind --erase ctrl-backspace 2>/dev/null
    bind --erase \b 2>/dev/null
end
