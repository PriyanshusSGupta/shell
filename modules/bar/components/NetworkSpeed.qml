pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import QtQuick

Column {
    id: root

    property color colour: Colours.palette.m3tertiary
    property int updateInterval: 1000
    property bool showIcons: true
    property bool compactMode: false

    spacing: 0
    width: 60  // Fixed width to prevent overflow
    
    Component.onCompleted: {
        console.log("NetworkSpeed component created! Monitoring enabled:", Network.monitoringEnabled)
        console.log("NetworkSpeed upload speed:", Network.uploadSpeed)
        console.log("NetworkSpeed download speed:", Network.downloadSpeed)
        console.log("NetworkSpeed active interface:", Network.activeInterface)
    }
    


    // Upload speed display
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 2

        // StyledText {
        //     anchors.verticalCenter: parent.verticalCenter
        //     text: "↑"
        //     font.pointSize: Appearance.font.size.smallest
        //     color: root.colour
        // }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: Network.monitoringEnabled ? formatCompactSpeed(Network.uploadSpeed) : "--"
            font.pointSize: Appearance.font.size.smallest
            font.family: Appearance.font.family.mono
            color: root.colour
            elide: Text.ElideRight
            width: 45
            horizontalAlignment: Text.AlignHCenter
        }
    }

    // Download speed display
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 2

        // StyledText {
        //     anchors.verticalCenter: parent.verticalCenter
        //     text: "↓"
        //     font.pointSize: Appearance.font.size.smallest
        //     color: root.colour
        // }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: Network.monitoringEnabled ? formatCompactSpeed(Network.downloadSpeed) : "--"
            font.pointSize: Appearance.font.size.smallest
            font.family: Appearance.font.family.mono
            color: root.colour
            elide: Text.ElideRight
            width: 45
            horizontalAlignment: Text.AlignHCenter
        }
    }

    // Compact function to format speeds (Kbps, Mbps, Gbps - no decimals)
    function formatCompactSpeed(speedStr) {
        if (!speedStr || speedStr === "0 bps") return "0"
        
        // Convert speeds to Kbps, Mbps, or Gbps without decimals
        const parts = speedStr.split(" ")
        if (parts.length >= 2) {
            const value = parseFloat(parts[0])
            const unit = parts[1]
            
            if (unit.startsWith("Gbps")) {
                return Math.round(value) + "G"
            }
            if (unit.startsWith("Mbps")) {
                return Math.round(value) + "M" 
            }
            if (unit.startsWith("Kbps")) {
                return Math.round(value) + "K"
            }
            if (unit.startsWith("bps")) {
                // Convert bps to Kbps
                return Math.round(value / 1000) + "K"
            }
        }
        
        return "0"
    }
}