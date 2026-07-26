# smb-restart (Unraid plugin)

Adds:
- A **Tools → Utilities → SMB Restart** page with live status and a restart/start button.
- A small status icon injected into the top navbar (near search/notifications/logout) that shows
  SMB's running state (green/red) and restarts (or starts) SMB on click.

SMB is controlled via Unraid's own `/etc/rc.d/rc.samba` script, so this uses the same start/stop
path Unraid itself uses when you toggle SMB in Settings — it won't fight with the OS.

## How the topbar icon works

Unraid doesn't have an official "add an icon to the topbar" extension point for plugins, so this
uses the same technique real-world Unraid plugins use: on every array start (`event/started`) the
plugin idempotently patches `/usr/local/emhttp/webGui/include/DefaultPageLayout.php` (the file
with the page's actual `</body>`) to load `javascript/smb-restart.js`.

On Unraid 7.x, the topbar itself (search/notifications/logout) is rendered by a web component
(`<unraid-header-os-version>`, shipped by the bundled `dynamix.my.servers` plugin), which likely
renders into a shadow root our script can't reach into or insert alongside. Because of that,
`javascript/smb-restart.js` doesn't try to squeeze into that tray — it renders its own small status
icon fixed to the top-right corner of the page, visually next to where those icons live, rather
than literally inside their container. If a future Unraid version exposes an open (non-shadow)
DOM for the topbar, `findTopbarContainer()` in that file can be updated to insert into it directly
instead. Uninstalling the plugin removes the `DefaultPageLayout.php` patch automatically.

## Files

```
smb-restart.plg                 - plugin installer manifest
source/smb-restart/...          - files installed onto Unraid, mirrors target paths:
  usr/local/emhttp/plugins/smb-restart/
    smb-restart.page            - Tools page (status + manual restart button)
    include/exec.php            - status/restart endpoint, calls rc.samba
    javascript/smb-restart.js   - topbar icon injection + polling
    event/started               - re-applies the DefaultPageLayout.php patch on every array start
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

### Option B — install from a local file path (no network needed)
1. Copy this whole directory to the Unraid server (e.g. via the `/boot` flash share or `scp`).
2. On the Unraid webGUI, go to **Plugins → Install Plugin**, and in the text field enter the
   absolute path to `smb-restart.plg` on the flash drive, e.g.:
   `/boot/config/plugins/smb-restart-src/smb-restart.plg`
3. This still needs `pkgURL` to resolve (either leave it pointing at GitHub, or edit it to a
   local path/URL reachable from the Unraid box).

### Option C — install the package directly (simplest for personal/single-box use)
1. `scp smb-restart-2026.07.25.2-noarch.txz root@<unraid-ip>:/boot/config/plugins/smb-restart/`
2. SSH into Unraid and run:
   ```
   upgradepkg --install-new --reinstall /boot/config/plugins/smb-restart/smb-restart-2026.07.25.2-noarch.txz
   /usr/local/emhttp/plugins/smb-restart/event/started
   ```
3. Reload the webGUI page — the icon should appear in the topbar, and **Tools → SMB Restart**
   will show the manual page.
4. To make this persist across reboots, also drop a copy of the `.txz` under
   `/boot/config/plugins/smb-restart/` (Option B's scp target already does this) — Unraid replays
   plugin installs from `/boot/config/plugins/` at boot for anything with a matching `.plg`, but
   for a manually-installed package without a `.plg` present you should instead add
   `upgradepkg --install-new --reinstall /boot/config/plugins/smb-restart/smb-restart-2026.07.25.2-noarch.txz`
   to your **Settings → User Scripts** "At Startup of Array" script, or use `go` file in
   `/boot/config/go`.

## Uninstall

Via Plugins page (if installed via `.plg`), or manually:
```
sed -i '/<!-- smb-restart:start -->/,/<!-- smb-restart:end -->/d' /usr/local/emhttp/webGui/include/DefaultPageLayout.php
removepkg smb-restart-2026.07.25.2-noarch
rm -rf /boot/config/plugins/smb-restart
```

## Customizing where the icon lands

If the icon doesn't show up next to search/logout on your Unraid version, open
`source/smb-restart/usr/local/emhttp/plugins/smb-restart/javascript/smb-restart.js` and inspect
your topbar's HTML (right-click → Inspect near the search icon) to find the right container
selector, add it to the `selectors` array in `findTopbarContainer()`, then re-run `./build.sh`
and reinstall.
