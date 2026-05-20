#!/usr/bin/env bash
#
# Build go-grip inside a Fedora toolbox and install the static binary into
# ~/.local/bin. Nothing is installed on the host (atomic) base system.
#
# By default it builds in a dedicated 'go-grip-build' toolbox, separate from any
# toolbox you use day to day. All build artifacts (module cache, output) live in
# a temp dir under ~/.cache and are deleted on exit.
#
# Env overrides:
#   TOOLBOX=go-grip-build    # toolbox container to build in
#   GOGRIP_VERSION=latest    # module version / tag
#   DEST_DIR=~/.local/bin    # where the binary lands on the host
#   REMOVE_TOOLBOX=0         # 1 = delete the build toolbox afterwards
#                            #     (only if THIS script created it)
#
set -euo pipefail

TOOLBOX="${TOOLBOX:-go-grip-build}"
GOGRIP_VERSION="${GOGRIP_VERSION:-latest}"
DEST_DIR="${DEST_DIR:-$HOME/.local/bin}"
REMOVE_TOOLBOX="${REMOVE_TOOLBOX:-0}"
MODULE="github.com/chrishrb/go-grip"

# Self-contained build area under $HOME (shared with the toolbox). GOPATH lives
# here too, so the module cache never pollutes ~/go.
BUILD_DIR="$(mktemp -d "$HOME/.cache/go-grip-build.XXXXXX")"
created_toolbox=0

cleanup() {
    # Go's module cache marks files read-only; make them removable first.
    chmod -R u+w "$BUILD_DIR" 2>/dev/null || true
    rm -rf "$BUILD_DIR"
    if [ "$REMOVE_TOOLBOX" = "1" ] && [ "$created_toolbox" = "1" ]; then
        echo ">> Removing build toolbox '$TOOLBOX'..."
        toolbox rm --force "$TOOLBOX" >/dev/null 2>&1 || true
    fi
}
trap cleanup EXIT

echo ">> Ensuring toolbox '$TOOLBOX' exists..."
if ! toolbox list --containers | grep -qw "$TOOLBOX"; then
    toolbox create "$TOOLBOX"
    created_toolbox=1
fi

echo ">> Ensuring Go is available in '$TOOLBOX'..."
toolbox run --container "$TOOLBOX" sh -c \
    'command -v go >/dev/null 2>&1 || sudo dnf install -y golang'

echo ">> Building $MODULE@$GOGRIP_VERSION (static, CGO disabled)..."
toolbox run --container "$TOOLBOX" env \
    CGO_ENABLED=0 \
    GOPATH="$BUILD_DIR/gopath" \
    GOBIN="$BUILD_DIR/bin" \
    GOFLAGS=-trimpath \
    go install "$MODULE@$GOGRIP_VERSION"

echo ">> Installing static binary into $DEST_DIR..."
mkdir -p "$DEST_DIR"
install -m 0755 "$BUILD_DIR/bin/go-grip" "$DEST_DIR/go-grip"

# Sanity check: confirm the copied binary is static and runs on the host.
if file "$DEST_DIR/go-grip" | grep -q "statically linked\|static-pie"; then
    echo ">> Verified statically linked."
fi
echo ">> Done: $DEST_DIR/go-grip"
