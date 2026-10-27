#!/usr/bin/env sh
set -eu

CONF="${XDG_CONFIG_HOME:-$HOME/.config}/fish"
rm -f "$CONF/functions/_dpath_kill.fish" "$CONF/conf.d/dpath.fish"

NU_AUTOLOAD=""
if command -v nu >/dev/null 2>&1; then
    NU_AUTOLOAD=$(nu --no-config-file -c 'print ($nu.data-dir | path join "vendor/autoload")' 2>/dev/null) || NU_AUTOLOAD=""
fi
[ -n "$NU_AUTOLOAD" ] || NU_AUTOLOAD="${XDG_DATA_HOME:-$HOME/.local/share}/nushell/vendor/autoload"
rm -f "$NU_AUTOLOAD/dpath.nu"

echo "dpath removed. Restart your shell to clear the key bindings."
