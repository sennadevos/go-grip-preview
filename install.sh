#!/usr/bin/env bash
#
# Install the go-grip user service + helpers by COPYING files into their standard
# locations. Nothing here is symlinked, so this clone is disposable: you can
# clone, run ./install.sh, then delete the clone and everything keeps working.
#
# To update later: pull/re-clone and run ./install.sh again.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UNIT="go-grip.service"
UNIT_DIR="$HOME/.config/systemd/user"
BIN_DIR="$HOME/.local/bin"
NVIM_LUA="$HOME/.config/nvim/lua/config"

if [ ! -x "$BIN_DIR/go-grip" ]; then
    echo "!! go-grip not found at $BIN_DIR/go-grip — run ./build.sh first." >&2
    exit 1
fi

# --- systemd user service ---
# rm first so we cleanly replace any earlier symlink with a real file.
rm -f "$UNIT_DIR/$UNIT"
install -Dm644 "$SCRIPT_DIR/$UNIT" "$UNIT_DIR/$UNIT"
systemctl --user daemon-reload
systemctl --user reenable "$UNIT"   # refreshes enablement symlink to the copied unit
systemctl --user start "$UNIT"

# --- preview-md CLI (copy of open-md.sh, onto PATH) ---
rm -f "$BIN_DIR/preview-md"
install -Dm755 "$SCRIPT_DIR/open-md.sh" "$BIN_DIR/preview-md"

# --- Neovim command/keymap, if a Neovim config is present ---
if [ -d "$NVIM_LUA" ]; then
    rm -f "$NVIM_LUA/markdown-preview.lua"
    install -Dm644 "$SCRIPT_DIR/nvim/markdown-preview.lua" "$NVIM_LUA/markdown-preview.lua"
    echo ">> Installed Neovim module into $NVIM_LUA"
    echo "   (ensure your init.lua has: pcall(require, 'config.markdown-preview'))"
fi

echo
systemctl --user --no-pager status "$UNIT" || true
echo
echo ">> go-grip serving \$HOME at http://localhost:6419"
echo ">> CLI:    preview-md <file.md>"
echo ">> Neovim: :MarkdownPreview  or  <leader>pm"
echo ">> Files were copied into place — you can safely delete this clone."
