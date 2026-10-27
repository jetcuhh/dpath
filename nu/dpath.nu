def _dpath_trim [text: string] {
    if $text =~ '/$' {
        $text | str replace --regex '[^/\s]*/$' ''
    } else if $text =~ '[^/\s]$' {
        $text | str replace --regex '[^/\s]+$' ''
    } else {
        let stripped = ($text | str replace --regex '\s+$' '')
        if ($stripped | is-empty) { $stripped } else { _dpath_trim $stripped }
    }
}

def _dpath_kill [] {
    let chars = (commandline | split chars --grapheme-clusters)
    let pos = (commandline get-cursor)
    let head = (_dpath_trim ($chars | first $pos | str join))
    let tail = ($chars | skip $pos | str join)

    commandline edit --replace ($head + $tail)
    commandline set-cursor ($head | str length --grapheme-clusters)
}

const _dpath_names = ["dpath_ctrl_backspace" "dpath_ctrl_h"]
const _dpath_event = { send: "executehostcommand", cmd: "_dpath_kill" }

$env.config.keybindings = (
    ($env.config.keybindings? | default [])
    | where {|kb| ($kb.name? | default "") not-in $_dpath_names }
    | append [
        {
            name: dpath_ctrl_backspace
            modifier: control
            keycode: backspace
            mode: [emacs vi_insert]
            event: $_dpath_event
        }
        {
            name: dpath_ctrl_h
            modifier: control
            keycode: char_h
            mode: [emacs vi_insert]
            event: $_dpath_event
        }
    ]
)
