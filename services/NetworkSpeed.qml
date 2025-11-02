pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property real downloadSpeed: 0  // in bytes per second
    property real uploadSpeed: 0    // in bytes per second
    property real downloadSpeedKB: downloadSpeed / 1024
    property real uploadSpeedKB: uploadSpeed / 1024
    property real downloadSpeedMB: downloadSpeed / (1024 * 1024)
    property real uploadSpeedMB: uploadSpeed / (1024 * 1024)

    property real lastRxBytes: 0
    property real lastTxBytes: 0
    property real lastTime: 0

    property int refCount: 0

    function formatSpeed(bytesPerSec: real): string {
        const kbps = bytesPerSec / 1024;
        const mbps = kbps / 1024;
        
        if (mbps >= 1) {
            return `${mbps.toFixed(1)} MB/s`;
        } else if (kbps >= 1) {
            return `${kbps.toFixed(1)} KB/s`;
        } else {
            return `${bytesPerSec.toFixed(0)} B/s`;
        }
    }

    Timer {
        running: root.refCount > 0
        interval: 1000  // Update every second
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            netstat.running = true;
        }
    }

    Process {
        id: netstat

        command: ["sh", "-c", "cat /proc/net/dev | grep -v 'lo:' | awk 'NR>2 {rx+=$2; tx+=$10} END {print rx, tx}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(/\s+/);
                if (parts.length >= 2) {
                    const currentRx = parseFloat(parts[0]) || 0;
                    const currentTx = parseFloat(parts[1]) || 0;
                    const currentTime = Date.now() / 1000;

                    if (root.lastTime > 0) {
                        const timeDiff = currentTime - root.lastTime;
                        if (timeDiff > 0) {
                            root.downloadSpeed = (currentRx - root.lastRxBytes) / timeDiff;
                            root.uploadSpeed = (currentTx - root.lastTxBytes) / timeDiff;
                        }
                    }

                    root.lastRxBytes = currentRx;
                    root.lastTxBytes = currentTx;
                    root.lastTime = currentTime;
                }
            }
        }
    }
}
