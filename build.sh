#!/bin/bash
# Builds the smb-restart-<version>-noarch.txz Slackware package from source/.
# Run this on Linux/macOS with bash + tar (no Unraid-specific tools needed).
set -euo pipefail

NAME="smb-restart"
VERSION="2026.07.25.2"
PKG="${NAME}-${VERSION}-noarch.txz"
SRC="source/${NAME}"

chmod +x "${SRC}/usr/local/emhttp/plugins/${NAME}/event/started"

# Strip any macOS resource-fork / Finder metadata files (._*, .DS_Store) that
# accumulate under source/ when working on macOS, so they don't ship in the package.
find "${SRC}" \( -name '._*' -o -name '.DS_Store' \) -delete

rm -f "${PKG}"
COPYFILE_DISABLE=1 tar --numeric-owner --owner=0 --group=0 --exclude='._*' --exclude='.DS_Store' \
    -cJf "${PKG}" -C "${SRC}" .

echo "Built ${PKG}"
md5sum "${PKG}" 2>/dev/null || md5 "${PKG}"
