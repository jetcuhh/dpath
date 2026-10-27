#!/usr/bin/env sh
set -eu

usage() {
    echo "usage: uninstall.sh [fish|nu|both]"
    echo "  With no argument, shows a picker (up/down or j/k, Enter to choose, q to"
    echo "  cancel). When there is no terminal to ask on, removes dpath from both."
    echo "  Piped: curl -fsSL https://raw.githubusercontent.com/jetcuhh/dpath/main/uninstall.sh | sh -s -- nu"
}

have_tty() { (: </dev/tty) 2>/dev/null; }

pick() {
    _prompt=$1; PICK=$2; shift 2
    _n=$#
    _esc=$(printf '\033')
    _etx=$(printf '\003')
    _saved=$(stty -g </dev/tty)
    trap 'stty "$_saved" </dev/tty; printf "\033[?25h" >/dev/tty' EXIT
    trap 'exit 130' INT TERM
    stty -icanon -echo -isig min 1 time 0 </dev/tty
    printf '\033[?25l%s\n' "$_prompt" >/dev/tty
    _drawn=0
    while :; do
        if [ "$_drawn" = 1 ]; then printf '\033[%dA' "$_n" >/dev/tty; fi
        _drawn=1
        _i=0
        for _o in "$@"; do
            _i=$((_i + 1))
            if [ "$_i" = "$PICK" ]; then
                printf '\033[2K\r\033[1;36m> %s\033[0m\n' "$_o" >/dev/tty
            else
                printf '\033[2K\r  %s\n' "$_o" >/dev/tty
            fi
        done
        _k=$(dd bs=1 count=1 </dev/tty 2>/dev/null)
        case "$_k" in
            "$_esc")
                stty min 0 time 1 </dev/tty
                _k=$(dd bs=1 count=2 </dev/tty 2>/dev/null)
                stty min 1 time 0 </dev/tty
                case "$_k" in
                    "[A" | "OA") if [ "$PICK" -gt 1 ]; then PICK=$((PICK - 1)); fi ;;
                    "[B" | "OB") if [ "$PICK" -lt "$_n" ]; then PICK=$((PICK + 1)); fi ;;
                esac ;;
            k) if [ "$PICK" -gt 1 ]; then PICK=$((PICK - 1)); fi ;;
            j) if [ "$PICK" -lt "$_n" ]; then PICK=$((PICK + 1)); fi ;;
            "$_etx") echo "dpath: cancelled" >&2; exit 130 ;;
            q) echo "dpath: cancelled" >&2; exit 1 ;;
            "") break ;;
        esac
    done
    stty "$_saved" </dev/tty
    printf '\033[?25h' >/dev/tty
    trap - EXIT INT TERM
}

TARGET="${1:-}"
case "$TARGET" in
    "" | fish | nu | both) ;;
    nushell) TARGET=nu ;;
    all) TARGET=both ;;
    -h | --help) usage; exit 0 ;;
    *) echo "dpath: unknown option '$TARGET'" >&2; usage >&2; exit 1 ;;
esac

if [ -z "$TARGET" ]; then
    if have_tty; then
        pick "Remove dpath from:" 3 fish nu both
        case "$PICK" in
            1) TARGET=fish ;;
            2) TARGET=nu ;;
            3) TARGET=both ;;
        esac
    else
        TARGET=both
    fi
fi

if [ "$TARGET" = fish ] || [ "$TARGET" = both ]; then
    CONF="${XDG_CONFIG_HOME:-$HOME/.config}/fish"
    rm -f "$CONF/functions/dpath_kill.fish" "$CONF/conf.d/dpath.fish"
    echo "dpath removed from fish. Restart fish to clear the key bindings."
fi

if [ "$TARGET" = nu ] || [ "$TARGET" = both ]; then
    NU_AUTOLOAD=""
    if command -v nu >/dev/null 2>&1; then
        NU_AUTOLOAD=$(nu --no-config-file -c 'print ($nu.data-dir | path join "vendor/autoload")' 2>/dev/null) || NU_AUTOLOAD=""
    fi
    [ -n "$NU_AUTOLOAD" ] || NU_AUTOLOAD="${XDG_DATA_HOME:-$HOME/.local/share}/nushell/vendor/autoload"
    rm -f "$NU_AUTOLOAD/dpath.nu"
    echo "dpath removed from Nushell. Restart nu to clear the key bindings."
fi
