#!/bin/bash
# Builds the smb-restart-<version>-noarch.txz Slackware package from source/.
# Run this on Linux/macOS with bash + tar (no Unraid-specific tools needed).
set -euo pipefail

NAME="smb-restart"
VERSION="2026.07.25.8"
PKG="${NAME}-${VERSION}-noarch.txz"
SRC="source/${NAME}"
PLG="${NAME}.plg"

# Catch invalid XML in the .plg before it ever gets pushed/installed — a
# literal "<" in CHANGES text (e.g. "</body>", "<img>") parses as a real,
# unmatched tag and breaks the whole file for Unraid's plugin installer.
python3 - "${PLG}" <<'EOF'
import sys, xml.parsers.expat
p = xml.parsers.expat.ParserCreate()
p.DefaultHandler = lambda data: None
with open(sys.argv[1], 'rb') as f:
    data = f.read()
try:
    p.Parse(data, True)
except Exception as e:
    print(f"ERROR: {sys.argv[1]} is not well-formed XML: {e}", file=sys.stderr)
    sys.exit(1)
EOF

# Strip any macOS resource-fork / Finder metadata files (._*, .DS_Store) that
# accumulate under source/ when working on macOS, so they don't ship in the package.
find "${SRC}" \( -name '._*' -o -name '.DS_Store' \) -delete

rm -f "${PKG}"
COPYFILE_DISABLE=1 tar --numeric-owner --owner=0 --group=0 --exclude='._*' --exclude='.DS_Store' \
    -cJf "${PKG}" -C "${SRC}" .

echo "Built ${PKG}"
md5sum "${PKG}" 2>/dev/null || md5 "${PKG}"
