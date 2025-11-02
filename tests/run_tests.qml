import QtQuick 2.15
import QtTest 1.15
import "."

Item {
    NetworkSpeedTest {
        when: windowShown
    }
    
    NetworkSpeedComponentTest {
        when: windowShown
    }
}