import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    Component.onCompleted: NetworkSpeed.refCount++
    Component.onDestruction: NetworkSpeed.refCount--

    ColumnLayout {
        id: content

        anchors.centerIn: parent
        spacing: Appearance.spacing.smaller

        // Download speed
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Appearance.spacing.smaller

            MaterialIcon {
                text: "download"
                font.pointSize: Appearance.font.size.small
                color: Colours.palette.m3primary
                Layout.alignment: Qt.AlignVCenter
            }

            StyledText {
                text: NetworkSpeed.formatSpeed(NetworkSpeed.downloadSpeed)
                font.pointSize: Appearance.font.size.small
                font.family: Appearance.font.family.mono
                color: Colours.palette.m3onSurface
                Layout.alignment: Qt.AlignVCenter
            }
        }

        // Upload speed
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Appearance.spacing.smaller

            MaterialIcon {
                text: "upload"
                font.pointSize: Appearance.font.size.small
                color: Colours.palette.m3secondary
                Layout.alignment: Qt.AlignVCenter
            }

            StyledText {
                text: NetworkSpeed.formatSpeed(NetworkSpeed.uploadSpeed)
                font.pointSize: Appearance.font.size.small
                font.family: Appearance.font.family.mono
                color: Colours.palette.m3onSurface
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}
