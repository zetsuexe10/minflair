import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services

Item {
    id: root

    property string page: "overview"
    property bool active: true
    readonly property var pages: ["overview", "apps", "speed"]
    readonly property alias initialFocusItem: keyCatcher
    readonly property alias speed: speedTest
    readonly property color soft: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08)
    readonly property color softBorder: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.07)
    property bool _watching: false

    signal closeRequested()

    function openPage(p) {
        page = p;
    }

    function syncWatch() {
        if (active && !_watching) {
            NetMonitorService.watchers += 1;
            _watching = true;
        } else if (!active && _watching) {
            NetMonitorService.watchers -= 1;
            _watching = false;
        }
    }

    function shift(dir) {
        const i = pages.indexOf(page);
        page = pages[(i + dir + pages.length) % pages.length];
    }

    function hue(id) {
        let h = 0;
        for (let i = 0; i < id.length; i++)
            h = (h * 31 + id.charCodeAt(i)) % 360;
        return Qt.hsla(h / 360, 0.45, 0.55, 1);
    }

    function fmtMbps(v) {
        if (v >= 100)
            return Math.round(v).toString();
        if (v >= 10)
            return v.toFixed(1);
        return v.toFixed(2);
    }

    implicitWidth: 420
    implicitHeight: 312
    onActiveChanged: syncWatch()
    Component.onCompleted: syncWatch()
    Component.onDestruction: {
        active = false;
        syncWatch();
    }

    SpeedTestBackend {
        id: speedTest
    }

    Item {
        id: keyCatcher

        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: root.closeRequested()
        Keys.onLeftPressed: root.shift(-1)
        Keys.onRightPressed: root.shift(1)
        Keys.onReturnPressed: {
            if (root.page === "speed")
                speedTest.running ? speedTest.stop() : speedTest.start();
        }
    }

    Rectangle {
        id: tabBar

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        height: 42
        radius: 21
        color: root.soft

        Row {
            anchors.fill: parent
            anchors.margins: 4
            spacing: 4

            Repeater {
                model: [
                    { "id": "overview", "label": "Overview" },
                    { "id": "apps", "label": "Apps" },
                    { "id": "speed", "label": "Speed test" }
                ]

                delegate: Rectangle {
                    required property var modelData

                    width: (tabBar.width - 8 - 8) / 3
                    height: parent.height
                    radius: height / 2
                    color: root.page === modelData.id ? Theme.accent : "transparent"

                    Behavior on color {
                        ColorAnimation { duration: Constants.animFast }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: modelData.label
                        font.pixelSize: 13
                        font.bold: true
                        color: root.page === modelData.id ? Theme.opaqueBg : Theme.muted
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.page = modelData.id
                    }
                }
            }
        }
    }

    Item {
        id: body

        anchors.top: tabBar.bottom
        anchors.topMargin: 12
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        Item {
            id: overviewPage

            anchors.fill: parent
            opacity: root.page === "overview" ? 1 : 0
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation { duration: Constants.animFast }
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: 150
                    spacing: 10

                    Repeater {
                        model: [
                            { "label": "Download", "down": true },
                            { "label": "Upload", "down": false }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            readonly property real rate: modelData.down ? NetMonitorService.rxRate : NetMonitorService.txRate
                            readonly property real avg: modelData.down ? NetMonitorService.avgRx : NetMonitorService.avgTx
                            readonly property real peak: modelData.down ? NetMonitorService.peakRx : NetMonitorService.peakTx

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 22
                            color: root.soft
                            border.width: 1
                            border.color: root.softBorder
                            clip: true

                            Sparkline {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: 60
                                values: modelData.down ? NetMonitorService.rxHistory : NetMonitorService.txHistory
                                lineColor: modelData.down ? Theme.accent : Theme.accentComplementary
                                floorMax: 131072
                            }

                            Column {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.margins: 14
                                spacing: 3

                                Text {
                                    text: modelData.label
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: Theme.muted
                                }

                                Text {
                                    text: NetMonitorService.formatRate(rate)
                                    font.pixelSize: 21
                                    font.bold: true
                                    color: Theme.fg
                                }

                                Text {
                                    text: "avg " + NetMonitorService.formatRate(avg)
                                    font.pixelSize: 11
                                    color: Theme.muted
                                }

                                Text {
                                    text: "peak " + NetMonitorService.formatRate(peak)
                                    font.pixelSize: 11
                                    color: Theme.muted
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    Layout.preferredHeight: 62
                    Layout.maximumHeight: 62
                    spacing: 10

                    Repeater {
                        model: [
                            { "label": "Received", "value": NetMonitorService.formatBytes(NetMonitorService.totalRx) },
                            { "label": "Sent", "value": NetMonitorService.formatBytes(NetMonitorService.totalTx) },
                            { "label": "CPU", "value": Math.round(SystemStats.cpuUsage) + "%" },
                            { "label": "Memory", "value": Math.round(SystemStats.memUsage) + "%" }
                        ]

                        delegate: Rectangle {
                            required property var modelData

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 18
                            color: root.soft
                            border.width: 1
                            border.color: root.softBorder

                            Column {
                                anchors.centerIn: parent
                                spacing: 2

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.value
                                    font.pixelSize: 14
                                    font.bold: true
                                    color: Theme.fg
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.label
                                    font.pixelSize: 10
                                    color: Theme.muted
                                }
                            }
                        }
                    }
                }
            }
        }

        Item {
            id: appsPage

            anchors.fill: parent
            opacity: root.page === "apps" ? 1 : 0
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation { duration: Constants.animFast }
            }

            Text {
                anchors.centerIn: parent
                visible: AppHistoryService.entries.length === 0
                text: "Apps you use will show up here"
                font.pixelSize: 13
                color: Theme.muted
            }

            ListView {
                anchors.fill: parent
                clip: true
                spacing: 6
                model: AppHistoryService.entries
                boundsBehavior: Flickable.StopAtBounds

                delegate: Rectangle {
                    required property var modelData
                    readonly property bool current: modelData.id === AppHistoryService.currentId

                    width: ListView.view.width
                    height: 50
                    radius: 18
                    color: current ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18) : root.soft
                    border.width: 1
                    border.color: current ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.4) : root.softBorder

                    Rectangle {
                        id: avatar

                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 34
                        height: 34
                        radius: 17
                        color: root.hue(modelData.id)

                        Text {
                            anchors.centerIn: parent
                            text: AppHistoryService.prettyName(modelData.id).charAt(0)
                            font.pixelSize: 15
                            font.bold: true
                            color: "#ffffff"
                        }
                    }

                    Column {
                        anchors.left: avatar.right
                        anchors.leftMargin: 10
                        anchors.right: usage.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1

                        Text {
                            width: parent.width
                            text: AppHistoryService.prettyName(modelData.id)
                            elide: Text.ElideRight
                            font.pixelSize: 13
                            font.bold: true
                            color: Theme.fg
                        }

                        Text {
                            text: current ? "Using now" : AppHistoryService.ago(modelData.last)
                            font.pixelSize: 11
                            color: current ? Theme.accent : Theme.muted
                        }
                    }

                    Text {
                        id: usage

                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: AppHistoryService.formatDuration(modelData.seconds || 0)
                        font.pixelSize: 12
                        font.bold: true
                        color: Theme.muted
                    }
                }
            }
        }

        Item {
            id: speedPage

            anchors.fill: parent
            opacity: root.page === "speed" ? 1 : 0
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation { duration: Constants.animFast }
            }

            Rectangle {
                id: gauge

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 136
                radius: 24
                color: root.soft
                border.width: 1
                border.color: root.softBorder
                clip: true

                Sparkline {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 54
                    values: speedTest.liveHistory
                    lineColor: speedTest.state === "upload" ? Theme.accentComplementary : Theme.accent
                    floorMax: 20
                }

                Rectangle {
                    id: goButton

                    anchors.centerIn: parent
                    width: 92
                    height: 92
                    radius: 46
                    visible: speedTest.state === "idle" && speedTest.lastDown < 0
                    color: goArea.containsMouse ? Qt.lighter(Theme.accent, 1.1) : Theme.accent
                    scale: goArea.pressed ? 0.95 : 1

                    Behavior on scale {
                        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "GO"
                        font.pixelSize: 26
                        font.bold: true
                        color: Theme.opaqueBg
                    }

                    MouseArea {
                        id: goArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: speedTest.start()
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 0
                    visible: !goButton.visible

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: speedTest.running ? root.fmtMbps(speedTest.liveMbps) : (speedTest.state === "done" ? root.fmtMbps(speedTest.downMbps) : (speedTest.lastDown >= 0 ? root.fmtMbps(speedTest.lastDown) : "0"))
                        font.pixelSize: 46
                        font.bold: true
                        color: Theme.fg
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: {
                            if (speedTest.state === "starting")
                                return "Finding a server";
                            if (speedTest.state === "latency")
                                return "Measuring latency";
                            if (speedTest.state === "download")
                                return "Mbps · downloading";
                            if (speedTest.state === "upload")
                                return "Mbps · uploading";
                            if (speedTest.state === "error")
                                return speedTest.message;
                            return speedTest.lastAt !== "" ? "Mbps · last test " + speedTest.lastAt : "Mbps";
                        }
                        width: gauge.width - 32
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        font.pixelSize: 12
                        color: speedTest.state === "error" ? Theme.accentComplementary : Theme.muted
                    }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    width: parent.width * speedTest.progress
                    height: 3
                    color: Theme.accent
                    visible: speedTest.running
                }
            }

            RowLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: gauge.bottom
                anchors.topMargin: 10
                height: 58
                spacing: 10

                Repeater {
                    model: [
                        { "label": "Ping", "value": speedTest.pingMs >= 0 ? Math.round(speedTest.pingMs) + " ms" : (speedTest.lastPing >= 0 ? Math.round(speedTest.lastPing) + " ms" : "-") },
                        { "label": "Download", "value": speedTest.state === "done" || speedTest.running ? root.fmtMbps(speedTest.downMbps) + " Mbps" : (speedTest.lastDown >= 0 ? root.fmtMbps(speedTest.lastDown) + " Mbps" : "-") },
                        { "label": "Upload", "value": speedTest.state === "done" || speedTest.running ? (speedTest.upMbps > 0 ? root.fmtMbps(speedTest.upMbps) + " Mbps" : "-") : (speedTest.lastUp >= 0 ? root.fmtMbps(speedTest.lastUp) + " Mbps" : "-") }
                    ]

                    delegate: Rectangle {
                        required property var modelData

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 18
                        color: root.soft
                        border.width: 1
                        border.color: root.softBorder

                        Column {
                            anchors.centerIn: parent
                            spacing: 2

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.value
                                font.pixelSize: 14
                                font.bold: true
                                color: Theme.fg
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.label
                                font.pixelSize: 10
                                color: Theme.muted
                            }
                        }
                    }
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 44
                radius: 22
                visible: !goButton.visible
                color: speedTest.running ? root.soft : Theme.accent

                Behavior on color {
                    ColorAnimation { duration: Constants.animFast }
                }

                Text {
                    anchors.centerIn: parent
                    text: speedTest.running ? "Stop" : (speedTest.state === "done" || speedTest.state === "error" ? "Test again" : "Start test")
                    font.pixelSize: 14
                    font.bold: true
                    color: speedTest.running ? Theme.fg : Theme.opaqueBg
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: speedTest.running ? speedTest.stop() : speedTest.start()
                }
            }
        }
    }
}
