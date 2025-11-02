import QtQuick 2.15
import QtQuick.Window 2.15
import "../modules/bar/components"

Window {
    id: window
    width: 200
    height: 300
    visible: true
    title: "NetworkSpeed Component Test"
    
    // Mock services for testing
    QtObject {
        id: mockNetwork
        property bool monitoringEnabled: true
        property string uploadSpeed: "1.2 MB/s"
        property string downloadSpeed: "5.4 MB/s"
        property string activeInterface: "wlan0"
    }
    
    QtObject {
        id: mockColours
        property var palette: QtObject {
            property color m3tertiary: "#6750A4"
            property color m3error: "#BA1A1A"
        }
    }
    
    QtObject {
        id: mockAppearance
        property var spacing: QtObject {
            property real small: 4
            property real smaller: 2
        }
        property var font: QtObject {
            property var size: QtObject {
                property real smaller: 10
            }
            property var family: QtObject {
                property string mono: "monospace"
            }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 20
        
        Text {
            text: "NetworkSpeed Component Test"
            font.bold: true
        }
        
        Rectangle {
            width: 150
            height: 100
            border.color: "gray"
            border.width: 1
            
            NetworkSpeed {
                anchors.centerIn: parent
                colour: "#6750A4"
                
                // Mock the global singletons by overriding the component
                Component.onCompleted: {
                    // This is a simplified test - in real usage these would be global singletons
                }
            }
        }
        
        Text {
            text: "Status: " + (mockNetwork.monitoringEnabled ? "Monitoring" : "Disabled")
        }
        
        Row {
            spacing: 10
            
            Rectangle {
                width: 80
                height: 30
                color: "lightblue"
                border.color: "blue"
                
                Text {
                    anchors.centerIn: parent
                    text: "Toggle"
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        mockNetwork.monitoringEnabled = !mockNetwork.monitoringEnabled
                    }
                }
            }
            
            Rectangle {
                width: 80
                height: 30
                color: "lightgreen"
                border.color: "green"
                
                Text {
                    anchors.centerIn: parent
                    text: "Change"
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        mockNetwork.uploadSpeed = Math.random() * 10 + " MB/s"
                        mockNetwork.downloadSpeed = Math.random() * 50 + " MB/s"
                    }
                }
            }
        }
    }
}