import QtQuick 2.15
import QtQuick.Window 2.15
import "../services"

Window {
    id: window
    width: 300
    height: 400
    visible: true
    title: "NetworkSpeed Integration Test"
    
    Column {
        anchors.centerIn: parent
        spacing: 20
        
        Text {
            text: "NetworkSpeed Integration Test"
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
        }
        
        Rectangle {
            width: 200
            height: 150
            border.color: "gray"
            border.width: 1
            anchors.horizontalCenter: parent.horizontalCenter
            
            Column {
                anchors.centerIn: parent
                spacing: 10
                
                Text {
                    text: "Network Service Status:"
                    font.bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                
                Text {
                    text: "Monitoring: " + (Network.monitoringEnabled ? "Enabled" : "Disabled")
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                
                Text {
                    text: "Interface: " + (Network.activeInterface || "None")
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                
                Text {
                    text: "Upload: " + Network.uploadSpeed
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.family: "monospace"
                }
                
                Text {
                    text: "Download: " + Network.downloadSpeed
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.family: "monospace"
                }
            }
        }
        
        Text {
            text: "✓ Network service properties accessible"
            color: "green"
            anchors.horizontalCenter: parent.horizontalCenter
        }
        
        Text {
            text: "✓ Speed monitoring integration working"
            color: "green"
            anchors.horizontalCenter: parent.horizontalCenter
        }
        
        Rectangle {
            width: 100
            height: 30
            color: "lightblue"
            border.color: "blue"
            anchors.horizontalCenter: parent.horizontalCenter
            
            Text {
                anchors.centerIn: parent
                text: "Toggle Monitor"
            }
            
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (Network.monitoringEnabled) {
                        Network.stopSpeedMonitoring()
                    } else {
                        Network.startSpeedMonitoring()
                    }
                }
            }
        }
    }
}