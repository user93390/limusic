#!/usr/bin/env bash
set -euo pipefail

NU_VERSION="${NU_VERSION:-0.114.1}"
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"

case "$(uname -m)" in
  x86_64)
    NU_ARCH="x86_64-unknown-linux-gnu"
    ;;
  aarch64|arm64)
    NU_ARCH="aarch64-unknown-linux-gnu"
    ;;
  *)
    echo "Unsupported architecture: $(uname -m)" >&2
    exit 1
    ;;
esac

mkdir -p "$INSTALL_DIR"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

archive="$tmpdir/nu.tar.gz"

curl -fsSL \
  "https://github.com/nushell/nushell/releases/download/${NU_VERSION}/nu-${NU_VERSION}-${NU_ARCH}.tar.gz" \
  -o "$archive"

tar -xzf "$archive" -C "$tmpdir"

install \
  "$tmpdir/nu-${NU_VERSION}-${NU_ARCH}/nu" \
  "$INSTALL_DIR/nu"

"$INSTALL_DIR/nu" --version

echo "Nushell ${NU_VERSION} installed to ${INSTALL_DIR}/nu"