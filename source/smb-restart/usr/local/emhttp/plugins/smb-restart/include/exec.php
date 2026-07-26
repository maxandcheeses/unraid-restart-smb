<?php
header('Content-Type: application/json');

function smb_running() {
    exec('pidof smbd', $out, $ret);
    return $ret === 0;
}

$action = $_GET['action'] ?? 'status';

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
