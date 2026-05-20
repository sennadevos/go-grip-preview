# go-grip-preview

A small, modular setup that keeps a [go-grip](https://github.com/chrishrb/go-grip)
Markdown preview server always running for your user, serving your whole home
directory. Built for an **atomic / immutable** host: nothing is installed on the
base system — the binary is compiled in a toolbox and copied into `~/.local/bin`.

## Layout

| File                | Responsibility                                              |
|---------------------|-------------------------------------------------------------|
| `build.sh`          | Compile go-grip in a toolbox, copy the static binary to `~/.local/bin`. |
| `go-grip.service`   | The systemd **user** unit (source of truth lives here).     |
| `install.sh`        | Symlink the unit into `~/.config/systemd/user` and enable it. |
| `uninstall.sh`      | Disable and remove the unit (keeps the binary).             |
| `open-md.sh`        | Open a single Markdown file in Floorp via the running service. |
| `nvim/markdown-preview.lua` | Neovim command + keymap that previews the current file. |

Each step is independent: rebuild the binary without touching the service, or
edit the service without rebuilding.

## Quick start

```bash
./build.sh      # compile in toolbox -> ~/.local/bin/go-grip
./install.sh    # enable + start the user service
```

Then open <http://localhost:6419> — you'll get a file tree of every Markdown
file under your home directory, rendered GitHub-style.

To jump straight to one file in your browser (Floorp):

```bash
./open-md.sh ~/Documenten/notes.md
```

This relies on the running service and just opens the right URL. For a global
shortcut, symlink it onto your PATH:

```bash
ln -sf "$PWD/open-md.sh" ~/.local/bin/preview-md
preview-md ~/some/file.md
```

## Neovim integration

`install.sh` symlinks `nvim/markdown-preview.lua` into
`~/.config/nvim/lua/config/` and puts `preview-md` on your `$PATH`. Add this line
to your `init.lua` (done once; it lives in your dotfiles, not here):

```lua
pcall(require, 'config.markdown-preview')  -- from go-grip-preview repo (symlinked)
```

Then, with any file open:

- `:MarkdownPreview` — render the current file in the browser
- `<leader>pm` — same, via keymap

The Lua module just shells out to `preview-md`, so all the URL logic lives in one
place (`open-md.sh`).

> Note: this intentionally fragments a slice of your Neovim config into this
> repo. The `require` line stays in your dotfiles (the source of truth); the
> implementation is symlinked in from here.

## How it works

- `build.sh` builds inside a dedicated `go-grip-build` toolbox (created on
  demand, separate from any toolbox you use day to day), installing `golang`
  there and using `CGO_ENABLED=0` so the result is a static binary safe to run
  on the host. The module cache and all output live in a temp dir under
  `~/.cache` and are deleted on exit — `~/go` is never touched. Override with
  env vars:
  ```bash
  # build in a custom toolbox and delete it afterwards
  TOOLBOX=go-grip-build REMOVE_TOOLBOX=1 GOGRIP_VERSION=v0.6.0 ./build.sh
  ```
  Set `REMOVE_TOOLBOX=1` to throw the build toolbox away after building (only
  removes it if the script created it). Leave it `0` for fast iterative rebuilds.
- `go-grip.service` runs `go-grip -b=false -p 6419 %h`. `%h` is your home
  directory and `-b=false` stops it from spawning a browser on every boot.

## Common tasks

```bash
# Status / logs
systemctl --user status go-grip
journalctl --user -u go-grip -f

# Change the port or flags (creates a drop-in override; survives unit edits)
systemctl --user edit go-grip

# Update go-grip to the latest release
./build.sh && systemctl --user restart go-grip

# Remove the service
./uninstall.sh
```

## Notes

- The service is a **user** unit, so it runs while you're logged in. To keep it
  running after you log out, enable lingering once:
  ```bash
  loginctl enable-linger "$USER"
  ```
- The unit is symlinked (not copied), so editing `go-grip.service` here and
  running `systemctl --user daemon-reload` is enough to pick up changes.
