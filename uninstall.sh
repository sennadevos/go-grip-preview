#!/usr/bin/env bash
#
# Disable and remove the go-grip user service.
# Leaves the ~/.local/bin/go-grip binary in place (remove it manually if you
# also want the binary gone).
#
set -euo pipefail

UNIT="go-grip.service"
UNIT_DIR="$HOME/.config/systemd/user"

systemctl --user disable --now "$UNIT" 2>/dev/null || true
rm -f "$UNIT_DIR/$UNIT"
systemctl --user daemon-reload

# Remove the symlinks install.sh created (leave the go-grip binary in place).
rm -f "$HOME/.local/bin/preview-md"
rm -f "$HOME/.config/nvim/lua/config/markdown-preview.lua"

echo ">> Removed $UNIT and the preview-md / Neovim symlinks."
echo ">> Binary at ~/.local/bin/go-grip and the require line in init.lua left intact."
