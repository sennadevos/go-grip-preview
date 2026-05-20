#!/usr/bin/env bash
#
# Open a Markdown file in the browser via the already-running go-grip service.
# Usage: open-md.sh path/to/file.md
#
set -euo pipefail

PORT="${GOGRIP_PORT:-6419}"

[ $# -ge 1 ] || { echo "Usage: $(basename "$0") <file.md>" >&2; exit 1; }

file="$(realpath -- "$1")"
[ -f "$file" ] || { echo "!! Not a file: $file" >&2; exit 1; }

# Canonicalize $HOME too: on atomic systems /home is a symlink to /var/home,
# so realpath of the file resolves there and must be compared against the same.
home="$(realpath -- "$HOME")"

# The service serves $HOME, which go-grip mounts under /<basename of $HOME>/.
case "$file" in
    "$home"/*) rel="${file#"$home"/}" ;;
    *) echo "!! $file is outside \$HOME; the go-grip service only serves \$HOME." >&2; exit 1 ;;
esac

url="http://localhost:${PORT}/$(basename "$home")/${rel// /%20}"

echo ">> Opening $url"
flatpak run one.ablaze.floorp "$url" >/dev/null 2>&1 &
disown
