#!/usr/bin/env sh
set -eu

REPO="jetcuhh/dpath"
BRANCH="${DPATH_BRANCH:-main}"
BASE="https://raw.githubusercontent.com/$REPO/$BRANCH"

command -v curl >/dev/null 2>&1 || { echo "dpath: curl is required" >&2; exit 1; }

have_fish=0
have_nu=0
if command -v fish >/dev/null 2>&1; then have_fish=1; fi
if command -v nu >/dev/null 2>&1; then have_nu=1; fi

if [ "$have_fish" = 0 ] && [ "$have_nu" = 0 ]; then
    echo "dpath: neither fish nor nu (Nushell) is installed" >&2
    exit 1
fi

if [ "$have_fish" = 1 ]; then
    CONF="${XDG_CONFIG_HOME:-$HOME/.config}/fish"
    mkdir -p "$CONF/functions" "$CONF/conf.d"

    curl -fsSL "$BASE/functions/_dpath_kill.fish" -o "$CONF/functions/_dpath_kill.fish"
    curl -fsSL "$BASE/conf.d/dpath.fish" -o "$CONF/conf.d/dpath.fish"

    echo "dpath installed to $CONF"
    echo "Open a new fish session (or run: source $CONF/conf.d/dpath.fish)"
fi

if [ "$have_nu" = 1 ]; then
    NU_AUTOLOAD=$(nu --no-config-file -c 'print ($nu.data-dir | path join "vendor/autoload")' 2>/dev/null) || NU_AUTOLOAD=""
    [ -n "$NU_AUTOLOAD" ] || NU_AUTOLOAD="${XDG_DATA_HOME:-$HOME/.local/share}/nushell/vendor/autoload"
    mkdir -p "$NU_AUTOLOAD"

    curl -fsSL "$BASE/nu/dpath.nu" -o "$NU_AUTOLOAD/dpath.nu"

    echo "dpath installed to $NU_AUTOLOAD"
    echo "Open a new nu session (or run: source $NU_AUTOLOAD/dpath.nu)"
fi
