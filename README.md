# smb-restart (Unraid plugin)

Adds:
- A real **nav-item button** in the topbar, right next to search/notifications/logout, that shows
  SMB's running state and restarts (or starts) SMB on click.
- A **Tools → Utilities → SMB Restart** page with live status and a restart/start button, for the
  same action without needing the topbar.

SMB is controlled via Unraid's own `/etc/rc.d/rc.samba` script, so this uses the same start/stop
path Unraid itself uses when you toggle SMB in Settings — it won't fight with the OS.

## How the topbar button works

Unraid's topbar buttons (search, notifications, logout, the power button, etc.) are, on the
webGUI's non-sidebar theme, rendered server-side by `webGui/include/DefaultPageLayout/Navigation/Main.php`
from `find_pages('Buttons')` in `webGui/include/PageBuilder.php` — i.e. any installed `.page` file
with `Menu="Buttons"` in its header automatically becomes a `nav-item` button in that same row. This
is the exact mechanism Unraid's own power button uses (`dynamix.system.buttons/PowerButton.page`).

`SmbRestart.page` in this plugin does exactly that — no core-file patching, no DOM-injection
guessing, no shadow-DOM workarounds. Its icon (`icons/smb-restart.png`) is looked up from the
plugin's own `icons/` directory, and its inline `<script>` block (following the same pattern as
`PowerButton.page`) finds its own `nav-item.SmbRestart a` element, wires up the click handler, and
polls `include/exec.php?action=status` every 15s to keep the icon's state current.

(An earlier version of this plugin patched a core webGUI file to inject a floating status icon —
that approach is gone; this is simpler and correct.)

## Files

```
smb-restart.plg                 - plugin installer manifest
source/smb-restart/...          - files installed onto Unraid, mirrors target paths:
  usr/local/emhttp/plugins/smb-restart/
    SmbRestart.page              - Menu="Buttons" page -> real topbar nav-item button
    smb-restart.page             - Tools page (status + manual restart button)
    include/exec.php             - status/restart endpoint, calls rc.samba
    icons/smb-restart.png        - topbar button icon
    images/smb-restart.png       - Plugins-page listing icon (same artwork)
build.sh                        - packages source/ into the .txz Slackware package
```

## Build

```
./build.sh
```

This produces `smb-restart-<version>-noarch.txz` in this directory.

## Install on your Unraid server

### Option A — install straight from the GitHub URL (recommended)
This repo is hosted at `git@github.com:maxandcheeses/unraid-restart-smb.git`. `smb-restart.plg`'s
`pluginURL` points at the raw `.plg` on `main`, and its `pkgURL` points at that version's `.txz`
attached as a **GitHub Release asset** (tag `v<version>`) — the `.txz` itself is *not* committed
to `main` (it's gitignored), which keeps repo history source-only instead of accumulating binary
blobs on every release.

On the Unraid webGUI, go to **Plugins → Install Plugin**, and paste:
```
https://raw.githubusercontent.com/maxandcheeses/unraid-restart-smb/main/smb-restart.plg
```
Click Install. Unraid downloads the `.plg`, which in turn downloads the matching `.txz` from that
version's GitHub Release and installs it.

> Note: for this to resolve, a GitHub Release tagged `v<version>` must exist with the matching
> `.txz` attached, and its MD5 must match the `pkgMD5` entity in `smb-restart.plg`. The
> `release-manager` subagent (`.claude/agents/release-manager.md`) handles all of this — bumping
> the version, rebuilding, and running `gh release create` with the asset attached — when cutting
> a release.
>
> Also note: `raw.githubusercontent.com` is fronted by a CDN that can serve a stale cached copy of
> `main` for a few minutes after a push, inconsistently per request/PoP. If a fresh install/update
> doesn't pick up the version you just pushed, wait a few minutes and retry, or install from the
> exact commit SHA (`.../<sha>/smb-restart.plg`) instead of `main`, which is cached immutably.

### Option B — install from a local file path (no network needed)
1. Copy this whole directory to the Unraid server (e.g. via the `/boot` flash share or `scp`).
2. On the Unraid webGUI, go to **Plugins → Install Plugin**, and in the text field enter the
   absolute path to `smb-restart.plg` on the flash drive, e.g.:
   `/boot/config/plugins/smb-restart-src/smb-restart.plg`
3. This still needs `pkgURL` to resolve (either leave it pointing at GitHub, or edit it to a
   local path/URL reachable from the Unraid box).

### Option C — install the package directly (simplest for personal/single-box use)
1. `scp smb-restart-2026.08.04.4-noarch.txz root@<unraid-ip>:/boot/config/plugins/smb-restart/`
2. SSH into Unraid and run:
   ```
   upgradepkg --install-new --reinstall /boot/config/plugins/smb-restart/smb-restart-2026.08.04.4-noarch.txz
   ```
3. Reload the webGUI page — the button should appear in the topbar, and **Tools → SMB Restart**
   will show the manual page.
4. To make this persist across reboots, also drop a copy of the `.txz` under
   `/boot/config/plugins/smb-restart/` (Option B's scp target already does this) — Unraid replays
   plugin installs from `/boot/config/plugins/` at boot for anything with a matching `.plg`, but
   for a manually-installed package without a `.plg` present you should instead add
   `upgradepkg --install-new --reinstall /boot/config/plugins/smb-restart/smb-restart-2026.08.04.4-noarch.txz`
   to your **Settings → User Scripts** "At Startup of Array" script, or use `go` file in
   `/boot/config/go`.

## Uninstall

Via Plugins page (if installed via `.plg`), or manually:
```
removepkg smb-restart-2026.08.04.4-noarch
rm -rf /boot/config/plugins/smb-restart
```

## Note on plugin "descriptions"

Unraid's core webGUI doesn't render a free-text description for manually-installed (non-Community-
Applications) plugins — the Plugins page shows Name/Author/Version/icon, and the "Readme" button
shows the `<CHANGES>` block from the `.plg`, which is the only place to put user-facing release
notes for a plugin installed this way. A Community-Applications-store-style description requires
actually submitting the plugin to the CA feed (a separate, heavier process), which this repo does
not do.
