#!/usr/bin/env bash
#
# Disable and remove the go-grip user service and the copied helper files.
# Leaves the ~/.local/bin/go-grip binary in place (remove it manually if you
# also want the binary gone).
#
set -euo pipefail

UNIT="go-grip.service"
UNIT_DIR="$HOME/.config/systemd/user"

systemctl --user disable --now "$UNIT" 2>/dev/null || true
rm -f "$UNIT_DIR/$UNIT"
systemctl --user daemon-reload

# Remove the files install.sh copied (leave the go-grip binary in place).
rm -f "$HOME/.local/bin/preview-md"
rm -f "$HOME/.config/nvim/lua/config/markdown-preview.lua"

echo ">> Removed $UNIT, preview-md, and the Neovim module."
echo ">> Binary at ~/.local/bin/go-grip and the require line in init.lua left intact."
