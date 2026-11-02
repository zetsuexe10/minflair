import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Core
import qs.Core.Components
import qs.Core.Services

// The Dashboard tab, laid out like Caelestia's: weather and user on top, date, calendar and
// resource rings below, the media player on the right.
Item {
    id: root

    implicitWidth: 730
    implicitHeight: 410

    property string uptime: ""
    readonly property string home: Quickshell.env("HOME")

    Process {
        id: uptimeProc

        command: ["sh", "-c", "awk '{s=int($1); d=int(s/86400); h=int(s%86400/3600); m=int(s%3600/60); if (d>0) printf \"%dd %dh\", d, h; else if (h>0) printf \"%dh %dm\", h, m; else printf \"%dm\", m}' /proc/uptime"]
        stdout: StdioCollector {
            onStreamFinished: root.uptime = text.trim()
        }
    }

    Timer {
        interval: 60000
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: uptimeProc.running = true
    }

    RowLayout {
        anchors.fill: parent
        spacing: 10

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 132
                Layout.minimumHeight: 132
                Layout.maximumHeight: 132
                spacing: 10

                // ---- weather ----
                CaelCard {
                    Layout.preferredWidth: 190
                    Layout.fillHeight: true
                    corner: 30

                    TapHandler {
                        onTapped: if (!WeatherService.loaded) WeatherService.refresh()
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 2
                        visible: WeatherService.loaded

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 10

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: WeatherService.glyph
                                font.pixelSize: 38
                                color: SideState.primary
                            }

                            SideText {
                                anchors.verticalCenter: parent.verticalCenter
                                text: WeatherService.temp + WeatherService.unit
                                customSize: 24
                                font.bold: true
                            }
                        }

                        SideText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: WeatherService.description
                            color: SideState.muted
                        }

                        SideText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: WeatherService.city
                            customSize: 10
                            color: SideState.muted
                        }
                    }

                    SideText {
                        anchors.centerIn: parent
                        visible: !WeatherService.loaded
                        text: WeatherService.errorText !== "" ? WeatherService.errorText : "Loading weather..."
                        color: SideState.muted
                    }
                }

                // ---- user ----
                CaelCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 16

                        Rectangle {
                            Layout.preferredWidth: 84
                            Layout.preferredHeight: 84
                            Layout.alignment: Qt.AlignVCenter
                            radius: 42
                            color: SideState.cardHi
                            clip: true

                            Image {
                                id: face

                                anchors.fill: parent
                                source: "file://" + root.home + "/.face"
                                fillMode: Image.PreserveAspectCrop
                                sourceSize: Qt.size(168, 168)
                                visible: status === Image.Ready
                            }

                            SideText {
                                anchors.centerIn: parent
                                visible: face.status !== Image.Ready
                                text: (SystemStats.username || "?").charAt(0).toUpperCase()
                                customSize: 34
                                font.bold: true
                                color: SideState.primary
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 6

                            SideText {
                                text: SystemStats.username
                                customSize: 16
                                font.bold: true
                            }

                            Repeater {
                                model: [
                                    { "k": "os", "v": SystemInfoService.osName },
                                    { "k": "wm", "v": "Hyprland" },
                                    { "k": "up", "v": root.uptime }
                                ]

                                RowLayout {
                                    required property var modelData

                                    spacing: 8

                                    SideText {
                                        Layout.preferredWidth: 22
                                        text: parent.modelData.k
                                        color: SideState.primary
                                        customSize: 10
                                        font.bold: true
                                    }

                                    SideText {
                                        Layout.fillWidth: true
                                        text: parent.modelData.v
                                        elide: Text.ElideRight
                                        color: SideState.muted
                                    }
                                }
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 10

                // ---- date / time ----
                CaelCard {
                    Layout.preferredWidth: 74
                    Layout.fillHeight: true
                    corner: 20

                    readonly property date now: SystemInfoService.currentTime

                    Column {
                        anchors.centerIn: parent
                        spacing: 0

                        SideText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Qt.formatDate(parent.parent.now, "ddd")
                            color: SideState.primary
                            customSize: 12
                            font.bold: true
                        }

                        Item { width: 1; height: 10 }

                        SideText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: {
                                let h = parent.parent.now.getHours();
                                if (!SettingsService.clock24h)
                                    h = h % 12 || 12;
                                return h.toString().padStart(2, "0");
                            }
                            customSize: 30
                            font.bold: true
                        }

                        SideText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Qt.formatTime(parent.parent.now, "mm")
                            customSize: 30
                            font.bold: true
                            color: SideState.muted
                        }

                        Item { width: 1; height: 10 }

                        SideText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Qt.formatDate(parent.parent.now, "d MMM")
                            customSize: 11
                            color: SideState.muted
                        }
                    }
                }

                // ---- calendar ----
                CaelCard {
                    id: calCard

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    property int viewMonth: new Date().getMonth()
                    property int viewYear: new Date().getFullYear()
                    readonly property date today: SystemInfoService.currentTime
                    readonly property int firstDow: Qt.locale().firstDayOfWeek % 7
                    readonly property int offset: (new Date(viewYear, viewMonth, 1).getDay() - firstDow + 7) % 7

                    function shift(d) {
                        let m = viewMonth + d;
                        let y = viewYear;
                        if (m < 0) { m = 11; y--; }
                        if (m > 11) { m = 0; y++; }
                        viewMonth = m;
                        viewYear = y;
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true

                            Rectangle {
                                Layout.preferredWidth: 28
                                Layout.preferredHeight: 28
                                radius: 14
                                color: pv.hovered ? SideState.cardHi : "transparent"

                                SvgIcon {
                                    anchors.centerIn: parent
                                    icon: "chevron-left"
                                    iconSize: 16
                                    iconColor: SideState.fg
                                    flat: true
                                }

                                HoverHandler { id: pv; cursorShape: Qt.PointingHandCursor }
                                TapHandler { onTapped: calCard.shift(-1) }
                            }

                            SideText {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                text: Qt.locale().monthName(calCard.viewMonth) + " " + calCard.viewYear
                                font.bold: true
                                customSize: 13
                                color: SideState.primary

                                TapHandler {
                                    onTapped: {
                                        calCard.viewMonth = calCard.today.getMonth();
                                        calCard.viewYear = calCard.today.getFullYear();
                                    }
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 28
                                Layout.preferredHeight: 28
                                radius: 14
                                color: nx.hovered ? SideState.cardHi : "transparent"

                                SvgIcon {
                                    anchors.centerIn: parent
                                    icon: "chevron-right"
                                    iconSize: 16
                                    iconColor: SideState.fg
                                    flat: true
                                }

                                HoverHandler { id: nx; cursorShape: Qt.PointingHandCursor }
                                TapHandler { onTapped: calCard.shift(1) }
                            }
                        }

                        Grid {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            columns: 7

                            readonly property real cw: width / 7
                            readonly property real ch: (height) / 7

                            Repeater {
                                model: 7

                                Item {
                                    required property int index

                                    width: parent.cw
                                    height: parent.ch

                                    SideText {
                                        anchors.centerIn: parent
                                        text: Qt.locale().dayName((calCard.firstDow + index) % 7, Locale.NarrowFormat)
                                        color: SideState.muted
                                        customSize: 10
                                        font.bold: true
                                    }
                                }
                            }

                            Repeater {
                                model: 42

                                Item {
                                    id: cell

                                    required property int index
                                    readonly property date d: new Date(calCard.viewYear, calCard.viewMonth, 1 - calCard.offset + index)
                                    readonly property bool inMonth: d.getMonth() === calCard.viewMonth
                                    readonly property bool isToday: d.getDate() === calCard.today.getDate() && d.getMonth() === calCard.today.getMonth() && d.getFullYear() === calCard.today.getFullYear()

                                    width: parent.cw
                                    height: parent.ch

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: Math.min(parent.width, parent.height) - 2
                                        height: width
                                        radius: width / 2
                                        color: SideState.primary
                                        visible: cell.isToday
                                    }

                                    SideText {
                                        anchors.centerIn: parent
                                        text: cell.d.getDate()
                                        customSize: 11
                                        font.bold: cell.isToday
                                        color: cell.isToday ? SideState.surface : (cell.inMonth ? SideState.fg : SideState.muted)
                                        opacity: cell.inMonth || cell.isToday ? 1 : 0.5
                                    }
                                }
                            }
                        }
                    }
                }

                // ---- resources ----
                CaelCard {
                    Layout.preferredWidth: 84
                    Layout.fillHeight: true
                    corner: 20

                    Column {
                        anchors.centerIn: parent
                        spacing: 12

                        Repeater {
                            model: 3

                            CaelGauge {
                                id: gauge

                                required property int index
                                readonly property var modelData: [
                                    { "icon": "cpu", "v": SystemStats.cpuUsage / 100, "c": 0 },
                                    { "icon": "memory", "v": SystemStats.memUsage / 100, "c": 1 },
                                    { "icon": "disk", "v": SystemStats.disks.length > 0 ? SystemStats.disks[0].usage / 100 : 0, "c": 2 }
                                ][index]

                                width: 58
                                height: 58
                                stroke: 5
                                value: modelData.v
                                fg: modelData.c === 0 ? SideState.primary : (modelData.c === 1 ? SideState.secondary : SideState.tertiary)

                                SvgIcon {
                                    anchors.centerIn: parent
                                    icon: gauge.modelData.icon
                                    iconSize: 18
                                    iconColor: gauge.fg
                                    flat: true
                                }
                            }
                        }
                    }
                }
            }
        }

        CaelCard {
            Layout.preferredWidth: 200
            Layout.fillHeight: true
            corner: 36

            CaelMediaCard {
                anchors.fill: parent
            }
        }
    }
}
