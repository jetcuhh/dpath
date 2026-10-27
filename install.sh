#!/usr/bin/env sh
set -eu

REPO="jetcuhh/dpath"
BRANCH="${DPATH_BRANCH:-main}"
BASE="https://raw.githubusercontent.com/$REPO/$BRANCH"

usage() {
    echo "usage: install.sh [fish|nu|both]"
    echo "  With no argument, shows a picker (up/down or j/k, Enter to choose, q to"
    echo "  cancel). When there is no terminal to ask on, installs for every"
    echo "  supported shell it finds."
    echo "  Piped install: curl -fsSL $BASE/install.sh | sh -s -- nu"
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

command -v curl >/dev/null 2>&1 || { echo "dpath: curl is required" >&2; exit 1; }

have_fish=0
have_nu=0
if command -v fish >/dev/null 2>&1; then have_fish=1; fi
if command -v nu >/dev/null 2>&1; then have_nu=1; fi

if [ -z "$TARGET" ]; then
    if [ "$have_fish" = 1 ] && [ "$have_nu" = 1 ]; then
        default_name=both; default_num=3
    elif [ "$have_fish" = 1 ]; then
        default_name=fish; default_num=1
    elif [ "$have_nu" = 1 ]; then
        default_name=nu; default_num=2
    else
        echo "dpath: neither fish nor nu (Nushell) is installed" >&2
        exit 1
    fi

    if have_tty; then
        pick "Install dpath for:" "$default_num" fish nu both
        case "$PICK" in
            1) TARGET=fish ;;
            2) TARGET=nu ;;
            3) TARGET=both ;;
        esac
    else
        TARGET="$default_name"
    fi
fi

want_fish=0
want_nu=0
case "$TARGET" in
    fish) want_fish=1 ;;
    nu) want_nu=1 ;;
    both) want_fish=1; want_nu=1 ;;
esac

if [ "$want_fish" = 1 ] && [ "$have_fish" = 0 ]; then
    echo "dpath: fish is not installed" >&2
    exit 1
fi
if [ "$want_nu" = 1 ] && [ "$have_nu" = 0 ]; then
    echo "dpath: nu (Nushell) is not installed" >&2
    exit 1
fi

if [ "$want_fish" = 1 ]; then
    CONF="${XDG_CONFIG_HOME:-$HOME/.config}/fish"
    mkdir -p "$CONF/functions" "$CONF/conf.d"

    curl -fsSL "$BASE/functions/dpath_kill.fish" -o "$CONF/functions/dpath_kill.fish"
    curl -fsSL "$BASE/conf.d/dpath.fish"          -o "$CONF/conf.d/dpath.fish"

    echo "dpath installed to $CONF"
    echo "Open a new fish session (or run: source $CONF/conf.d/dpath.fish)"
fi

if [ "$want_nu" = 1 ]; then
    NU_AUTOLOAD=$(nu --no-config-file -c 'print ($nu.data-dir | path join "vendor/autoload")' 2>/dev/null) || NU_AUTOLOAD=""
    [ -n "$NU_AUTOLOAD" ] || NU_AUTOLOAD="${XDG_DATA_HOME:-$HOME/.local/share}/nushell/vendor/autoload"
    mkdir -p "$NU_AUTOLOAD"

    curl -fsSL "$BASE/nu/dpath.nu" -o "$NU_AUTOLOAD/dpath.nu"

    echo "dpath installed to $NU_AUTOLOAD"
    echo "Open a new nu session (or run: source $NU_AUTOLOAD/dpath.nu)"
fi
