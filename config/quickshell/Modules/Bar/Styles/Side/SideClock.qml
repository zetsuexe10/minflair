import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services

// Weekday and day on top, hours over minutes below. Click opens the calendar.
SidePill {
    id: root

    readonly property date now: SystemInfoService.currentTime
    readonly property string hours: {
        let h = now.getHours();
        if (!SettingsService.clock24h)
            h = h % 12 || 12;
        return h.toString().padStart(2, "0");
    }

    implicitWidth: 48
    implicitHeight: layout.implicitHeight + 18
    color: area.containsMouse || AppState.isWidgetOpen("calendar") ? Qt.tint(Theme.bg, Theme.bgSecondary) : Theme.bg

    Behavior on color { ColorAnimation { duration: Constants.animFast } }

    ColumnLayout {
        id: layout

        anchors.centerIn: parent
        spacing: 0

        ThemedText {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDate(root.now, "ddd")
            customSize: 10
            color: Theme.muted
        }

        ThemedText {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDate(root.now, "d")
            customSize: 15
            font.bold: true
            color: Theme.accent
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 4
            Layout.bottomMargin: 4
            implicitWidth: 18
            implicitHeight: 1
            color: Theme.border
        }

        ThemedText {
            Layout.alignment: Qt.AlignHCenter
            text: root.hours
            customSize: 15
            font.bold: true
        }

        ThemedText {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatTime(root.now, "mm")
            customSize: 15
            font.bold: true
        }

        ThemedText {
            Layout.alignment: Qt.AlignHCenter
            visible: !SettingsService.clock24h
            text: root.now.getHours() >= 12 ? "pm" : "am"
            customSize: 10
            color: Theme.muted
        }
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: AppState.toggleWidget("calendar")
    }
}
