import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services

// Vertical bar: weekday and day on top, hours over minutes below. Horizontal bar: one line.
// Click opens the calendar.
SidePill {
    id: root

    property bool vertical: true
    readonly property date now: SystemInfoService.currentTime
    readonly property string hours: {
        let h = now.getHours();
        if (!SettingsService.clock24h)
            h = h % 12 || 12;
        return h.toString().padStart(2, "0");
    }
    readonly property string suffix: SettingsService.clock24h ? "" : (now.getHours() >= 12 ? "pm" : "am")

    implicitWidth: vertical ? 44 : row.implicitWidth + 28
    implicitHeight: vertical ? col.implicitHeight + 18 : 44
    color: area.containsMouse || AppState.isWidgetOpen("calendar") ? Qt.tint(Theme.bg, Theme.bgSecondary) : Theme.bg

    Behavior on color { ColorAnimation { duration: Constants.animFast } }

    ColumnLayout {
        id: col

        visible: root.vertical
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
            visible: root.suffix !== ""
            text: root.suffix
            customSize: 10
            color: Theme.muted
        }
    }

    RowLayout {
        id: row

        visible: !root.vertical
        anchors.centerIn: parent
        spacing: 8

        ThemedText {
            text: Qt.formatDate(root.now, "ddd d")
            customSize: 12
            color: Theme.accent
            font.bold: true
        }

        Rectangle {
            implicitWidth: 1
            implicitHeight: 16
            color: Theme.border
        }

        ThemedText {
            text: root.hours + ":" + Qt.formatTime(root.now, "mm") + (root.suffix !== "" ? " " + root.suffix : "")
            customSize: 14
            font.bold: true
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
