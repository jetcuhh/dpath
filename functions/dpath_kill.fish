function dpath_kill --description "Backspace one path segment at a time"
    set -l before (commandline -c | string collect)
    set -l full (commandline | string collect)
    set -l pos (commandline -C)
    set -l after

    if string match -rq '/$' -- $before
        set after (string replace -r '[^/\s]*/$' '' -- $before | string collect)
    else if string match -rq '[^/\s]$' -- $before
        set after (string replace -r '[^/\s]+$' '' -- $before | string collect)
    else
        commandline -f backward-kill-word
        return
    end

    set -l tail (string sub -s (math $pos + 1) -- $full | string collect)
    commandline -r -- "$after$tail"
    commandline -C (string length -- $after)
end
