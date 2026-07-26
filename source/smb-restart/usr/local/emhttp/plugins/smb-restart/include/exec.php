<?php
header('Content-Type: application/json');

const CONFIG_FILE = '/boot/config/plugins/smb-restart/smb-restart.cfg';

function smb_running() {
    exec('pidof smbd', $out, $ret);
    return $ret === 0;
}

function nav_icon_shown() {
    $cfg = @parse_ini_file(CONFIG_FILE);
    return ($cfg['SHOW_NAV_ICON'] ?? 'true') !== 'false';
}

$action = $_GET['action'] ?? 'status';

if ($action === 'save-settings') {
    $show = ($_REQUEST['showNav'] ?? 'true') !== 'false';
    @mkdir(dirname(CONFIG_FILE), 0755, true);
    file_put_contents(CONFIG_FILE, "SHOW_NAV_ICON=\"" . ($show ? 'true' : 'false') . "\"\n");
    echo json_encode(['showNav' => $show]);
    exit;
}

if ($action === 'get-settings') {
    echo json_encode(['showNav' => nav_icon_shown()]);
    exit;
}

if ($action === 'restart') {
    $wasRunning = smb_running();
    // rc.samba handles both the "not running" and "running" cases correctly:
    // start if down, restart if up.
    if ($wasRunning) {
        exec('/etc/rc.d/rc.samba restart 2>&1', $out, $ret);
    } else {
        exec('/etc/rc.d/rc.samba start 2>&1', $out, $ret);
    }
    // Give smbd a moment to (re)bind before we report status back.
    usleep(800000);
    echo json_encode([
        'action'  => $wasRunning ? 'restarted' : 'started',
        'running' => smb_running(),
        'output'  => implode("\n", $out),
    ]);
    exit;
}

echo json_encode(['running' => smb_running()]);
