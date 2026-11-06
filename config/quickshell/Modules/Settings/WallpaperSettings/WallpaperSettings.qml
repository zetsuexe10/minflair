import "Components"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Settings.Components

AppContainer {
    id: wallpaperRoot

    AppGroup {
        title: "Wallpapers"
        icon: "picture"
        showDividers: false

        RowLayout {
            Layout.fillWidth: true
            spacing: Constants.sizeSm

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Constants.size3Xs

                ThemedText {
                    Layout.fillWidth: true
                    text: WallpaperManager.currentWallpaper !== "" ? WallpaperManager.currentWallpaper.split("/").pop() : "No wallpaper selected"
                    customSize: Constants.sizeSm
                    font.weight: Font.Medium
                    color: Theme.fg
                    elide: Text.ElideMiddle
                }

                ThemedText {
                    Layout.fillWidth: true
                    text: "Click a thumbnail to apply it now. Folders are scanned recursively."
                    customSize: Constants.sizeXs + 3
                    color: Theme.muted
                    wrapMode: Text.WordWrap
                }

            }

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: shuffleLabel.implicitWidth + 24
                implicitHeight: 30
                radius: 15
                color: shuffleArea.containsMouse ? Theme.bgTertiary : Theme.bgSecondary
                border.width: 1
                border.color: Theme.border

                ThemedText {
                    id: shuffleLabel

                    anchors.centerIn: parent
                    text: "Shuffle"
                    customSize: Constants.sizeXs + 2
                    color: Theme.fg
                }

                MouseArea {
                    id: shuffleArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: WallpaperManager.shuffle()
                }

            }

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: browseLabel.implicitWidth + 24
                implicitHeight: 30
                radius: 15
                color: browseArea.containsMouse ? Theme.bgTertiary : Theme.bgSecondary
                border.width: 1
                border.color: Theme.border

                ThemedText {
                    id: browseLabel

                    anchors.centerIn: parent
                    text: "Browse"
                    customSize: Constants.sizeXs + 2
                    color: Theme.fg
                }

                MouseArea {
                    id: browseArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: wallPicker.running = true
                }

            }

        }

        ListView {
            id: wallList

            Layout.fillWidth: true
            Layout.preferredHeight: 96
            orientation: ListView.Horizontal
            spacing: 10
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            visible: wallModel.count > 0

            ScrollBar.horizontal: ScrollBar {
                policy: ScrollBar.AlwaysOff
            }

            model: ListModel {
                id: wallModel
            }

            delegate: Item {
                required property var modelData

                readonly property bool isCurrent: WallpaperManager.currentWallpaperPath === modelData.rawPath

                width: 150
                height: 92

                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    color: Theme.bgSecondary
                    border.width: isCurrent ? 2 : 1
                    border.color: isCurrent ? Theme.accent : Theme.border
                    clip: true

                    Image {
                        anchors.fill: parent
                        anchors.margins: 4
                        source: "file://" + modelData.rawPath
                        sourceSize: Qt.size(150, 96)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 22
                        color: Qt.rgba(0, 0, 0, 0.55)

                        ThemedText {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            text: modelData.name
                            customSize: Constants.sizeXs
                            color: "white"
                            elide: Text.ElideMiddle
                        }

                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: WallpaperManager.applyWallpaperWithSync(WallpaperManager.storedName(modelData.rawPath), modelData.rawPath)
                    }

                }

            }

        }

        ThemedText {
            Layout.fillWidth: true
            visible: wallModel.count === 0
            text: "No wallpapers found. Add images to ~/Pictures/Wallpapers or /usr/share/backgrounds."
            customSize: Constants.sizeXs + 3
            color: Theme.muted
            wrapMode: Text.WordWrap
        }

    }

    Process {
        id: wallListProc

        property var lines: []

        command: WallpaperManager.listCommand
        running: true
        onRunningChanged: {
            if (running)
                lines = [];

        }
        onExited: {
            let sorted = lines.slice().sort((a, b) => a.name.localeCompare(b.name));
            wallModel.clear();
            for (let i = 0; i < sorted.length; i++) {
                wallModel.append(sorted[i]);
            }
            lines = [];
        }

        stdout: SplitParser {
            onRead: (data) => {
                const parts = data.split("\n");
                for (let i = 0; i < parts.length; i++) {
                    const rawPath = parts[i].trim();
                    if (rawPath !== "") {
                        const segs = rawPath.split("/");
                        wallListProc.lines.push({
                            "rawPath": rawPath,
                            "name": segs[segs.length - 1]
                        });
                    }
                }
            }
        }

    }

    Process {
        id: wallPicker

        command: ["sh", "-c", "zenity --file-selection --title='Wallpaper' --file-filter='Images | *.png *.jpg *.jpeg *.webp *.gif' 2>/dev/null || kdialog --getopenfilename \"$HOME\" 'image/*' 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim();
                if (p !== "")
                    WallpaperManager.applyWallpaperWithSync(WallpaperManager.storedName(p), p);
            }
        }

    }

    AppGroup {
        title: "Screen Framing & Cropping"
        icon: "picture-spark"
        showDividers: false

        WallpaperCropPreview {
            Layout.fillWidth: true
        }

        SettingSegmented {
            label: "Scaling Mode"
            description: "How wallpapers adapt across different aspect ratios"
            model: [{
                "text": "Crop (Fill)",
                "value": "crop"
            }, {
                "text": "Fit",
                "value": "fit"
            }, {
                "text": "Stretch",
                "value": "stretch"
            }]
            currentValue: HyprlandService.wpResizeMode
            onActivated: (val) => {
                HyprlandService.wpResizeMode = val;
            }
        }

    }

    AppGroup {
        title: "Automation & Transitions"
        icon: "sparkles"

        SettingToggle {
            id: autoShuffleToggle

            label: "Auto-shuffle Wallpapers"
            onCheckedChanged: {
                if (checked !== HyprlandService.wpAutoShuffle)
                    HyprlandService.wpAutoShuffle = checked;

            }

            Binding {
                target: autoShuffleToggle
                property: "checked"
                value: HyprlandService.wpAutoShuffle
            }

        }

        SettingSpinBox {
            enabled: HyprlandService.wpAutoShuffle
            opacity: enabled ? 1 : 0.5
            label: "Shuffle Interval"
            from: 1
            to: 60
            stepSize: 1
            value: HyprlandService.wpShuffleInterval
            suffix: " min"
            decimals: 0
            onMoved: (val) => {
                HyprlandService.wpShuffleInterval = Math.round(val);
            }
        }

        ThemedSelect {
            label: "Transition Type"
            model: ["none", "grow", "fade", "wipe", "wave", "random"]
            currentIndex: {
                if (!HyprlandService.wpEnableTransitions)
                    return 0;

                let idx = model.indexOf(HyprlandService.wpTransitionType);
                return idx !== -1 ? idx : 1;
            }
            onActivated: (index) => {
                let val = model[index];
                if (val === "none") {
                    HyprlandService.wpEnableTransitions = false;
                } else {
                    HyprlandService.wpEnableTransitions = true;
                    HyprlandService.wpTransitionType = val;
                }
            }
        }

        ThemedSelect {
            label: "Transition Position"
            model: ["top-left", "top", "top-right", "left", "center", "right", "bottom-left", "bottom", "bottom-right"]
            currentIndex: {
                let idx = model.indexOf(HyprlandService.wpTransitionPos);
                return idx !== -1 ? idx : 4;
            }
            onActivated: (index) => {
                HyprlandService.wpTransitionPos = model[index];
            }
            enabled: HyprlandService.wpEnableTransitions && HyprlandService.wpTransitionType !== "random"
            opacity: enabled ? 1 : 0.4

            Behavior on opacity {
                NumberAnimation {
                    duration: Constants.animFast
                }

            }

        }

        ColumnLayout {
            spacing: Constants.sizeLg
            Layout.fillWidth: true
            enabled: HyprlandService.wpEnableTransitions
            opacity: enabled ? 1 : 0.4

            SettingSegmented {
                label: "Transition Speed"
                model: [{
                    "text": "Slow",
                    "value": 60
                }, {
                    "text": "Normal",
                    "value": 120
                }, {
                    "text": "Fast",
                    "value": 180
                }, {
                    "text": "Ultra",
                    "value": 240
                }]
                currentValue: HyprlandService.wpTransitionStep
                onActivated: (val) => {
                    HyprlandService.wpTransitionStep = val;
                }
            }

            Divider {
            }

            SettingSegmented {
                label: "Transition Frame Rate"
                model: [{
                    "text": "30",
                    "value": 30
                }, {
                    "text": "60",
                    "value": 60
                }, {
                    "text": "120",
                    "value": 120
                }, {
                    "text": "144",
                    "value": 144
                }]
                currentValue: HyprlandService.wpTransitionFps
                onActivated: (val) => {
                    HyprlandService.wpTransitionFps = val;
                }
            }

            Divider {
                visible: HyprlandService.wpTransitionType === "wipe" || HyprlandService.wpTransitionType === "wave"
            }

            ThemedSlider {
                label: "Transition Angle"
                from: 0
                to: 360
                stepSize: 10
                value: HyprlandService.wpTransitionAngle
                suffix: "°"
                decimals: 0
                visible: HyprlandService.wpTransitionType === "wipe" || HyprlandService.wpTransitionType === "wave"
                onMoved: (val) => {
                    HyprlandService.wpTransitionAngle = Math.round(val);
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: Constants.animFast
                }

            }

        }

    }

}
