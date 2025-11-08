pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    
    // Not required to avoid early-binding errors during loader creation; we'll
    // guard uses of `bar` before accessing it.
    property var bar: null

    readonly property var active: Players.active

    Component.onCompleted: console.log("Media.qml loaded — size:", root.implicitWidth, root.implicitHeight)

    Layout.fillHeight: true
    // Use safe fallbacks in case Appearance/Config singletons are not ready
    implicitWidth: (Config && Config.bar && Config.bar.sizes ? Config.bar.sizes.innerWidth : 40)
    // Make the item tall enough so MouseArea and contents receive pointer events
    implicitHeight: (Config && Config.bar && Config.bar.sizes ? Config.bar.sizes.innerWidth : 40)


    Timer {
        running: active?.isPlaying == true
        interval: (Config && Config.options && Config.options.resources) ? Config.options.resources.updateInterval : 1000
        repeat: true
        onTriggered: if (active) active.positionChanged()
    }

    Rectangle {
        anchors.fill: parent        // cover the whole media item
        color: "#FFFF0000"        // fully opaque red for debugging
        border.color: "#80FF0000"
        border.width: 1
        radius: 2
    }


    RowLayout {
        id: rowLayout
        anchors.fill: parent
        anchors.margins: Appearance.padding.small
        spacing: 6

        Rectangle {
            id: artBg
            width: 28
            height: 28
            radius: 28/2
            color: (active && active.isPlaying) ? (Colours ? Colours.palette.m3primary : "#FF5555") : (Colours ? Colours.tPalette.m3surfaceContainer : "#222222")
            border.color: Colours ? Colours.palette.m3outline : "#000000"
            border.width: 0

            MaterialIcon {
                anchors.centerIn: parent
                text: active && active.isPlaying ? "pause" : "play_arrow"
                color: (active && active.isPlaying) ? (Colours ? Colours.palette.m3onPrimary : "#FFFFFF") : (Colours ? Colours.palette.m3onSurfaceVariant : "#FFFFFF")
                // Caelestia defines font sizes as Appearance.font.size.normal/small/etc.
                // 'medium' is from the end4 tree; map it to `normal` here.
                font.pixelSize: (Appearance && Appearance.font) ? Appearance.font.size.normal : 12
            }
        }

        StyledText {
            visible: Config.options.bar.verbose && root.implicitWidth > 80
            // StringUtils is not available in this tree; use a safe fallback instead
            // text: (active?.trackTitle || qsTr("No media")) + (active?.trackArtist ? ' • ' + active.trackArtist : '')
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            color: Colours ? Colours.palette.m3onSurfaceVariant : "#FFFFFF"
            Layout.fillWidth: true
        }
    }

    MouseArea {
        // Fill the entire media item so clicks are consistently received.
        anchors.fill: parent
        z: 2
        enabled: true
        acceptedButtons: Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton | Qt.RightButton | Qt.LeftButton
        hoverEnabled: true
        onPressed: (event) => {
            console.log("Media clicked, button:", event.button)
            if (event.button === Qt.MiddleButton) {
                if (active && active.canTogglePlaying) active.togglePlaying();
            } else if (event.button === Qt.BackButton) {
                if (active && active.canGoPrevious) active.previous();
            } else if (event.button === Qt.ForwardButton || event.button === Qt.RightButton) {
                if (active && active.canGoNext) active.next();
            } else if (event.button === Qt.LeftButton) {
                // Toggle the audio popout via the bar's popouts wrapper, guard in case bar/popouts isn't ready
                try {
                    if (bar && bar.popouts) {
                        bar.popouts.currentName = "audio";
                        // compute center immediately (avoid creating a binding that may evaluate early)
                        try {
                            const centerY = root.mapToItem(bar, 0, root.implicitHeight / 2).y;
                            bar.popouts.currentCenter = centerY;
                            console.log("Computed popout center Y:", centerY);
                        } catch (e) {
                            console.warn("Failed to compute popout center:", e);
                        }
                        bar.popouts.hasCurrent = true;
                    } else {
                        console.warn("bar or bar.popouts not available yet");
                    }
                } catch (e) {
                    console.warn("Failed to open audio popout:", e);
                }
            }
        }
    }
    
}
