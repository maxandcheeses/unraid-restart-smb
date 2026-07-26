#!/bin/bash
# Builds the smb-restart-<version>-noarch.txz Slackware package from source/.
# Run this on Linux/macOS with bash + tar (no Unraid-specific tools needed).
set -euo pipefail

NAME="smb-restart"
VERSION="2026.07.25.1"
PKG="${NAME}-${VERSION}-noarch.txz"
SRC="source/${NAME}"

chmod +x "${SRC}/usr/local/emhttp/plugins/${NAME}/event/started"

rm -f "${PKG}"
tar --numeric-owner --owner=0 --group=0 -cJf "${PKG}" -C "${SRC}" .

echo "Built ${PKG}"
md5sum "${PKG}" 2>/dev/null || md5 "${PKG}"
