import QtQuick 2.15
import QtTest 1.15
import "../modules/bar/components"

TestCase {
    id: componentTest
    name: "NetworkSpeedComponentTest"
    
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

    Component {
        id: networkSpeedComponent
        
        NetworkSpeed {
            // Mock the global singletons
            property var Network: mockNetwork
            property var Colours: mockColours
            property var Appearance: mockAppearance
        }
    }

    function test_componentCreation() {
        const component = networkSpeedComponent.createObject(componentTest);
        verify(component !== null, "Component should be created successfully");
        component.destroy();
    }

    function test_speedDisplayWithValidData() {
        mockNetwork.monitoringEnabled = true;
        mockNetwork.uploadSpeed = "1.2 MB/s";
        mockNetwork.downloadSpeed = "5.4 MB/s";
        mockNetwork.activeInterface = "wlan0";
        
        const component = networkSpeedComponent.createObject(componentTest);
        verify(component !== null);
        
        // Find the speed text elements
        const uploadText = findChild(component, function(child) {
            return child.text === "1.2 MB/s";
        });
        const downloadText = findChild(component, function(child) {
            return child.text === "5.4 MB/s";
        });
        
        verify(uploadText !== null, "Upload speed should be displayed");
        verify(downloadText !== null, "Download speed should be displayed");
        
        component.destroy();
    }

    function test_errorStateWhenMonitoringDisabled() {
        mockNetwork.monitoringEnabled = false;
        mockNetwork.activeInterface = "";
        
        const component = networkSpeedComponent.createObject(componentTest);
        verify(component !== null);
        
        // Should show fallback text when monitoring is disabled
        const fallbackText = findChild(component, function(child) {
            return child.text === "-- B/s";
        });
        
        verify(fallbackText !== null, "Should show fallback text when monitoring disabled");
        
        component.destroy();
    }

    function test_errorStateWhenNoInterface() {
        mockNetwork.monitoringEnabled = true;
        mockNetwork.activeInterface = "";
        
        const component = networkSpeedComponent.createObject(componentTest);
        verify(component !== null);
        
        // Should show error indicator when no interface
        const errorText = findChild(component, function(child) {
            return child.text === "No Network";
        });
        
        verify(errorText !== null, "Should show 'No Network' when no active interface");
        
        component.destroy();
    }

    function test_iconVisibilityToggle() {
        mockNetwork.monitoringEnabled = true;
        mockNetwork.uploadSpeed = "1.0 KB/s";
        mockNetwork.downloadSpeed = "2.0 KB/s";
        
        const component = networkSpeedComponent.createObject(componentTest, {
            showIcons: false
        });
        verify(component !== null);
        
        // Icons should not be visible when showIcons is false
        verify(!component.showIcons, "showIcons should be false");
        
        component.destroy();
    }

    function test_colourConsistency() {
        const component = networkSpeedComponent.createObject(componentTest, {
            colour: "#FF0000"
        });
        verify(component !== null);
        
        compare(component.colour, "#FF0000", "Component should accept custom colour");
        
        component.destroy();
    }

    function test_compactModeProperty() {
        const component = networkSpeedComponent.createObject(componentTest, {
            compactMode: true
        });
        verify(component !== null);
        
        verify(component.compactMode, "Compact mode should be settable");
        
        component.destroy();
    }

    function test_updateIntervalProperty() {
        const component = networkSpeedComponent.createObject(componentTest, {
            updateInterval: 2000
        });
        verify(component !== null);
        
        compare(component.updateInterval, 2000, "Update interval should be configurable");
        
        component.destroy();
    }

    // Helper function to find child components
    function findChild(parent, predicate) {
        if (predicate(parent)) {
            return parent;
        }
        
        for (let i = 0; i < parent.children.length; i++) {
            const result = findChild(parent.children[i], predicate);
            if (result !== null) {
                return result;
            }
        }
        
        return null;
    }
}