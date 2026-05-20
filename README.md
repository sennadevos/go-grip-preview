# go-grip-preview

A small, modular setup that keeps a [go-grip](https://github.com/chrishrb/go-grip)
Markdown preview server always running for your user, serving your whole home
directory. Built for an **atomic / immutable** host: nothing is installed on the
base system — the binary is compiled in a toolbox and copied into `~/.local/bin`.

Everything is **copied into place** on install (no symlinks back into this repo),
so the clone is disposable: clone → `./build.sh && ./install.sh` → delete the
clone, and it all keeps working from standard locations.

## Layout

| File                | Responsibility                                              |
|---------------------|-------------------------------------------------------------|
| `build.sh`          | Compile go-grip in a toolbox, copy the static binary to `~/.local/bin`. |
| `go-grip.service`   | The systemd **user** unit.                                  |
| `install.sh`        | Copy the unit, `preview-md`, and the nvim module into place, then enable + start. |
| `uninstall.sh`      | Disable and remove the unit + copied helpers (keeps the binary). |
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

`install.sh` also copies `open-md.sh` to `~/.local/bin/preview-md`, so to jump
straight to one file in your browser (Floorp):

```bash
preview-md ~/Documenten/notes.md
```

This relies on the running service and just opens the right URL.

## Neovim integration

`install.sh` copies `nvim/markdown-preview.lua` into
`~/.config/nvim/lua/config/` and puts `preview-md` on your `$PATH`. Add this line
to your `init.lua` (once; it lives in your dotfiles):

```lua
pcall(require, 'config.markdown-preview')
```

Then, with any file open:

- `:MarkdownPreview` — render the current file in the browser
- `<leader>pm` — same, via keymap

The Lua module just shells out to `preview-md`, so all the URL logic lives in one
place (`open-md.sh`). Re-run `./install.sh` after pulling to update the copied
module.

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
- Files are copied into place, so this clone is disposable. After editing
  anything here, re-run `./install.sh` to push the changes into your standard
  locations.
