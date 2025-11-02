pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property list<AccessPoint> networks: []
    readonly property AccessPoint active: networks.find(n => n.active) ?? null
    property bool wifiEnabled: true
    readonly property bool scanning: rescanProc.running

    // Speed monitoring properties
    property string uploadSpeed: "0 B/s"
    property string downloadSpeed: "0 B/s"
    property real rawUploadBytes: 0
    property real rawDownloadBytes: 0
    property string activeInterface: ""
    property bool monitoringEnabled: false

    // Internal speed monitoring state
    property var previousStats: null
    property real previousTimestamp: 0
    property var interfaceStats: null

    function enableWifi(enabled) {
        const cmd = enabled ? "on" : "off";
        enableWifiProc.exec(["nmcli", "radio", "wifi", cmd]);
    }

    function toggleWifi() {
        const cmd = wifiEnabled ? "off" : "on";
        enableWifiProc.exec(["nmcli", "radio", "wifi", cmd]);
    }

    function rescanWifi() {
        rescanProc.running = true;
    }

    function connectToNetwork(ssid, password) {
        // TODO: Implement password
        connectProc.exec(["nmcli", "conn", "up", ssid]);
    }

    function disconnectFromNetwork() {
        if (active) {
            disconnectProc.exec(["nmcli", "connection", "down", active.ssid]);
        }
    }

    function getWifiStatus() {
        wifiStatusProc.running = true;
    }

    // Speed monitoring functions
    function startSpeedMonitoring() {
        monitoringEnabled = true;
        detectActiveInterface();
        speedTimer.start();
    }

    function stopSpeedMonitoring() {
        monitoringEnabled = false;
        speedTimer.stop();
        uploadSpeed = "0 B/s";
        downloadSpeed = "0 B/s";
        rawUploadBytes = 0;
        rawDownloadBytes = 0;
    }

    function setMonitorInterface(interfaceName) {
        activeInterface = interfaceName;
        previousStats = null;
        previousTimestamp = 0;
    }

    function formatSpeed(bytesPerSecond) {
        // Convert bytes to bits (multiply by 8)
        const bitsPerSecond = bytesPerSecond * 8;
        
        if (bitsPerSecond < 1000) {
            return Math.round(bitsPerSecond) + " bps";
        } else if (bitsPerSecond < 1000 * 1000) {
            return (bitsPerSecond / 1000).toFixed(1) + " Kbps";
        } else if (bitsPerSecond < 1000 * 1000 * 1000) {
            return (bitsPerSecond / (1000 * 1000)).toFixed(1) + " Mbps";
        } else {
            return (bitsPerSecond / (1000 * 1000 * 1000)).toFixed(2) + " Gbps";
        }
    }

    function detectActiveInterface() {
        interfaceDetectionProc.running = true;
    }

    function parseInterfaceStats() {
        interfaceStatsProc.running = true;
    }

    function calculateSpeeds(stats) {
        const currentTime = Date.now();
        
        if (previousTimestamp > 0 && previousStats && previousStats.rxBytes !== undefined) {
            const timeDelta = (currentTime - previousTimestamp) / 1000.0; // Convert to seconds
            
            if (timeDelta > 0) {
                const rxDelta = stats.rxBytes - previousStats.rxBytes;
                const txDelta = stats.txBytes - previousStats.txBytes;
                
                rawDownloadBytes = Math.max(0, rxDelta / timeDelta);
                rawUploadBytes = Math.max(0, txDelta / timeDelta);
                
                downloadSpeed = formatSpeed(rawDownloadBytes);
                uploadSpeed = formatSpeed(rawUploadBytes);
            }
        }
        
        previousStats = stats;
        previousTimestamp = currentTime;
    }

    // Speed monitoring timer
    Timer {
        id: speedTimer
        interval: 1000
        repeat: true
        onTriggered: {
            if (monitoringEnabled && activeInterface) {
                parseInterfaceStats();
            }
        }
    }

    // Interface detection process
    Process {
        id: interfaceDetectionProc
        
        command: ["ip", "route", "get", "1.1.1.1"]
        stdout: StdioCollector {
            onStreamFinished: {
                // Parse output to find active interface
                // Example: "1.1.1.1 via 192.168.1.1 dev wlan0 src 192.168.1.100 uid 1000"
                const match = text.match(/dev\s+(\S+)/);
                if (match && match[1]) {
                    const detectedInterface = match[1];
                    if (activeInterface !== detectedInterface) {
                        setMonitorInterface(detectedInterface);
                    }
                } else {
                    // Fallback: try to find first active interface
                    fallbackIn
                    console.log("No interface found in route output, trying fallback");
                    // Fallback: try to find first active interface
                    fallbackInterfaceProc.running = true;
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                // If route detection fails, try fallback method
                fallbackInterfaceProc.running = true;
            }
        }
    }

    // Fallback interface detection
    Process {
        id: fallbackInterfaceProc
        
        command: ["ip", "link", "show", "up"]
        stdout: StdioCollector {
            onStreamFinished: {
                // Find first non-loopback interface that's up
                const lines = text.split('\n');
                for (const line of lines) {
                    const match = line.match(/^\d+:\s+(\S+):/);
                    if (match && match[1] && match[1] !== 'lo' && line.includes('state UP')) {
                        if (activeInterface !== match[1]) {
                            setMonitorInterface(match[1]);
                        }
                        break;
                    }
                }
            }
        }
    }

    // Interface statistics parsing process
    Process {
        id: interfaceStatsProc
        
        command: ["cat", "/proc/net/dev"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!activeInterface) return;
                
                const lines = text.split('\n');
                for (const line of lines) {
                    if (line.includes(activeInterface + ':')) {
                        // Parse the line: interface: rx_bytes rx_packets ... tx_bytes tx_packets ...
                        const parts = line.split(/\s+/).filter(part => part.length > 0);
                        if (parts.length >= 10) {
                            // Format: iface: rx_bytes rx_packets rx_errs rx_drop rx_fifo rx_frame rx_compressed rx_multicast tx_bytes tx_packets ...
                            const rxBytes = parseInt(parts[1]) || 0;
                            const txBytes = parseInt(parts[9]) || 0;
                            
                            calculateSpeeds({
                                rxBytes: rxBytes,
                                txBytes: txBytes
                            });
                        }
                        break;
                    }
                }
            }
        }
    }

    Process {
        running: true
        command: ["nmcli", "m"]
        stdout: SplitParser {
            onRead: getNetworks.running = true
        }
    }

    Process {
        id: wifiStatusProc

        running: true
        command: ["nmcli", "radio", "wifi"]
        environment: {
                "LANG": "C.UTF-8",
                "LC_ALL": "C.UTF-8"
            }
        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiEnabled = text.trim() === "enabled";
            }
        }
    }

    Process {
        id: enableWifiProc

        onExited: {
            root.getWifiStatus();
            getNetworks.running = true;
        }
    }

    Process {
        id: rescanProc

        command: ["nmcli", "dev", "wifi", "list", "--rescan", "yes"]
        onExited: {
            getNetworks.running = true;
        }
    }

    Process {
        id: connectProc

        stdout: SplitParser {
            onRead: getNetworks.running = true
        }
        stderr: StdioCollector {
            onStreamFinished: console.warn("Network connection error:", text)
        }
    }

    Process {
        id: disconnectProc

        stdout: SplitParser {
            onRead: getNetworks.running = true
        }
    }

    Process {
        id: getNetworks

        running: true
        command: ["nmcli", "-g", "ACTIVE,SIGNAL,FREQ,SSID,BSSID,SECURITY", "d", "w"]
        environment: {
                "LANG": "C.UTF-8",
                "LC_ALL": "C.UTF-8"
            }
        stdout: StdioCollector {
            onStreamFinished: {
                const PLACEHOLDER = "STRINGWHICHHOPEFULLYWONTBEUSED";
                const rep = new RegExp("\\\\:", "g");
                const rep2 = new RegExp(PLACEHOLDER, "g");

                const allNetworks = text.trim().split("\n").map(n => {
                    const net = n.replace(rep, PLACEHOLDER).split(":");
                    return {
                        active: net[0] === "yes",
                        strength: parseInt(net[1]),
                        frequency: parseInt(net[2]),
                        ssid: net[3]?.replace(rep2, ":") ?? "",
                        bssid: net[4]?.replace(rep2, ":") ?? "",
                        security: net[5] ?? ""
                    };
                }).filter(n => n.ssid && n.ssid.length > 0);

                // Group networks by SSID and prioritize connected ones
                const networkMap = new Map();
                for (const network of allNetworks) {
                    const existing = networkMap.get(network.ssid);
                    if (!existing) {
                        networkMap.set(network.ssid, network);
                    } else {
                        // Prioritize active/connected networks
                        if (network.active && !existing.active) {
                            networkMap.set(network.ssid, network);
                        } else if (!network.active && !existing.active) {
                            // If both are inactive, keep the one with better signal
                            if (network.strength > existing.strength) {
                                networkMap.set(network.ssid, network);
                            }
                        }
                        // If existing is active and new is not, keep existing
                    }
                }

                const networks = Array.from(networkMap.values());

                const rNetworks = root.networks;

                const destroyed = rNetworks.filter(rn => !networks.find(n => n.frequency === rn.frequency && n.ssid === rn.ssid && n.bssid === rn.bssid));
                for (const network of destroyed)
                    rNetworks.splice(rNetworks.indexOf(network), 1).forEach(n => n.destroy());

                for (const network of networks) {
                    const match = rNetworks.find(n => n.frequency === network.frequency && n.ssid === network.ssid && n.bssid === network.bssid);
                    if (match) {
                        match.lastIpcObject = network;
                    } else {
                        rNetworks.push(apComp.createObject(root, {
                            lastIpcObject: network
                        }));
                    }
                }
            }
        }
    }

    component AccessPoint: QtObject {
        required property var lastIpcObject
        readonly property string ssid: lastIpcObject.ssid
        readonly property string bssid: lastIpcObject.bssid
        readonly property int strength: lastIpcObject.strength
        readonly property int frequency: lastIpcObject.frequency
        readonly property bool active: lastIpcObject.active
        readonly property string security: lastIpcObject.security
        readonly property bool isSecure: security.length > 0
    }

    Component {
        id: apComp

        AccessPoint {}
    }

    // Initialize speed monitoring on component completion
    Component.onCompleted: {
        startSpeedMonitoring();
    }
}
