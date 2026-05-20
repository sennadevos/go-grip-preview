#!/usr/bin/env bash
#
# Install (symlink) the go-grip user service and enable it.
# The unit file stays here in the workspace as the source of truth; we just
# symlink it into the systemd user directory, so edits here take effect after
# a `systemctl --user daemon-reload`.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UNIT="go-grip.service"
UNIT_DIR="$HOME/.config/systemd/user"

if [ ! -x "$HOME/.local/bin/go-grip" ]; then
    echo "!! go-grip not found at ~/.local/bin/go-grip — run ./build.sh first." >&2
    exit 1
fi

mkdir -p "$UNIT_DIR"
ln -sf "$SCRIPT_DIR/$UNIT" "$UNIT_DIR/$UNIT"

systemctl --user daemon-reload
systemctl --user enable --now "$UNIT"

# Put `preview-md` on PATH (used by the Neovim integration and for quick CLI use).
mkdir -p "$HOME/.local/bin"
ln -sf "$SCRIPT_DIR/open-md.sh" "$HOME/.local/bin/preview-md"

# Wire the Neovim command/keymap in, if a Neovim config is present.
NVIM_LUA="$HOME/.config/nvim/lua/config"
if [ -d "$NVIM_LUA" ]; then
    ln -sf "$SCRIPT_DIR/nvim/markdown-preview.lua" "$NVIM_LUA/markdown-preview.lua"
    echo ">> Linked Neovim module into $NVIM_LUA"
    echo "   (ensure your init.lua has: pcall(require, 'config.markdown-preview'))"
fi

echo
systemctl --user --no-pager status "$UNIT" || true
echo
echo ">> go-grip is serving your home directory at http://localhost:6419"
echo ">> CLI:   preview-md <file.md>"
echo ">> Neovim: :MarkdownPreview  or  <leader>pm"
