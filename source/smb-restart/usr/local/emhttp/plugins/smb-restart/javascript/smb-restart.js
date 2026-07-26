/* smb-restart: shows a status/restart icon near the search / notifications /
 * logout icons in the top navbar.
 *
 * On Unraid 6.x the topbar is plain DOM, so this first tries a list of known
 * container selectors and inserts directly into them. On Unraid 7.x the
 * topbar is rendered by a web component (<unraid-header-os-version>, from
 * dynamix.my.servers) which likely uses a shadow root querySelector can't
 * see into or insert alongside — in that case (or on any future markup
 * change) this falls back to a small fixed-position icon pinned to the
 * top-right corner, next to but not literally inside that tray. */
(function () {
    'use strict';

    function findTopbarContainer() {
        var selectors = [
            '.trayicons',        // Unraid 6.x icon tray (update/notify icons)
            '#trayicons',
            'ul.list-right',
            '.top-right',
            '#user'               // fallback: insert right before the user/logout menu
        ];
        for (var i = 0; i < selectors.length; i++) {
            var el = document.querySelector(selectors[i]);
            if (el) return el;
        }
        return null;
    }

    function buildIcon() {
        var a = document.createElement('a');
        a.id = 'smb-restart-icon';
        a.title = 'SMB: checking...';
        a.href = '#';
        a.style.cssText = 'display:inline-flex;align-items:center;justify-content:center;' +
            'width:22px;height:22px;margin:0 8px;cursor:pointer;vertical-align:middle;';
        a.innerHTML = '<i class="fa fa-share-alt" style="font-size:15px;"></i>';
        return a;
    }

    function setState(el, running) {
        el.title = running ? 'SMB is running — click to restart' : 'SMB is stopped — click to start';
        var i = el.querySelector('i');
        i.style.color = running ? '#3c3' : '#c33';
    }

    function poll(el) {
        fetch('/plugins/smb-restart/include/exec.php?action=status')
            .then(function (r) { return r.json(); })
            .then(function (data) { setState(el, data.running); })
            .catch(function () {});
    }

    function init() {
        var container = findTopbarContainer();
        var icon = buildIcon();

        if (container) {
            container.insertBefore(icon, container.firstChild);
        } else {
            icon.style.position = 'fixed';
            icon.style.top = '12px';
            icon.style.right = '16px';
            icon.style.zIndex = 999999;
            icon.style.background = 'rgba(20,20,22,0.85)';
            icon.style.borderRadius = '50%';
            icon.style.boxShadow = '0 1px 4px rgba(0,0,0,0.4)';
            document.body.appendChild(icon);
        }

        icon.addEventListener('click', function (e) {
            e.preventDefault();
            icon.querySelector('i').className = 'fa fa-spinner fa-spin';
            fetch('/plugins/smb-restart/include/exec.php?action=restart')
                .then(function (r) { return r.json(); })
                .then(function (data) { setState(icon, data.running); })
                .catch(function () { poll(icon); });
        });

        poll(icon);
        setInterval(function () { poll(icon); }, 15000);
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
