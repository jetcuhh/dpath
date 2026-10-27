# dpath

Fish and Nushell plugin: **Ctrl+Backspace deletes one path segment at a time** instead of wiping the whole path.

```
cd /home/user/something  →  Ctrl+Backspace  →  cd /home/user/
```

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/jetcuhh/dpath/main/install.sh | sh
```

Or with fisher (fish):

```fish
fisher install jetcuhh/dpath
```

Restart your shell after installing.

## Key bindings

Fish: binds `ctrl-backspace` and `\b` by default.

Nushell: binds `Ctrl+Backspace` and `Ctrl+H` in emacs/vi_insert.

## License

MIT
