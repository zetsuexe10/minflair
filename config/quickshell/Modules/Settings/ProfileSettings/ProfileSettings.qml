import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Settings.Components

AppContainer {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string customSource: {
        let p = String(SettingsService.profileImage || "").trim();
        if (p === "")
            return "";

        if (p.startsWith("~/"))
            p = root.home + p.substring(1);

        return p.startsWith("file://") ? p : "file://" + p;
    }
    readonly property string pictureSource: customSource !== "" ? customSource : "file://" + root.home + "/.face"
    readonly property string distroSource: Quickshell.iconPath(SystemInfoService.osLogoName !== "" ? SystemInfoService.osLogoName : ("distributor-logo-" + SystemInfoService.osId), true)
    readonly property string pictureLabel: {
        const p = String(SettingsService.profileImage || "").trim();
        return p === "" ? "~/.face or distro logo" : p;
    }

    function setPicturePath(raw) {
        let p = String(raw || "").trim();
        if (p === "")
            return ;

        if (p.startsWith("file://"))
            p = decodeURIComponent(p.substring(7));

        if (p.startsWith("~/"))
            p = root.home + p.substring(1);

        SettingsService.profileImage = p;
    }

    Card {
        Layout.fillWidth: true
        contentPadding: Constants.sizeLg
        cardRadius: Constants.sizeSm
        useBorder: true

        RowLayout {
            width: parent.width
            height: implicitHeight
            spacing: Constants.sizeLg

            Rectangle {
                width: 84
                height: 84
                radius: width / 2
                color: "transparent"
                border.width: 2
                border.color: Theme.accent

                Rectangle {
                    id: avatarInner

                    anchors.centerIn: parent
                    width: 72
                    height: 72
                    radius: width / 2
                    color: Theme.bgSecondary
                    clip: true

                    ShaderEffectSource {
                        id: avatarMask

                        visible: false
                        hideSource: true
                        smooth: true
                        sourceItem: Rectangle {
                            width: avatarInner.width
                            height: avatarInner.height
                            radius: avatarInner.radius
                            antialiasing: true
                            color: Theme.white
                        }

                    }

                    Image {
                        id: avatarImage

                        anchors.fill: parent
                        source: root.pictureSource
                        fillMode: Image.PreserveAspectCrop
                        sourceSize: Qt.size(144, 144)
                        asynchronous: true
                        cache: true
                        visible: status === Image.Ready
                        layer.enabled: true

                        layer.effect: MultiEffect {
                            maskEnabled: true
                            maskThresholdMin: 0.5
                            maskSpreadAtMin: 1
                            maskSource: avatarMask
                        }

                    }

                    Image {
                        id: avatarDistro

                        anchors.centerIn: parent
                        width: 44
                        height: 44
                        source: avatarImage.visible ? "" : root.distroSource
                        fillMode: Image.PreserveAspectFit
                        sourceSize: Qt.size(88, 88)
                        visible: status === Image.Ready && !avatarImage.visible
                    }

                    ThemedText {
                        anchors.centerIn: parent
                        visible: !avatarImage.visible && !avatarDistro.visible
                        text: (SystemStats.username || "?").charAt(0).toUpperCase()
                        customSize: Constants.sizeXl
                        font.bold: true
                        color: Theme.accent
                    }

                }

            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Constants.size3Xs

                ThemedText {
                    Layout.fillWidth: true
                    text: (SystemStats.username || "User") + "@" + (SystemStats.hostname || "")
                    customSize: Constants.sizeMd
                    font.weight: Font.Bold
                    color: Theme.fg
                    elide: Text.ElideRight
                }

                ThemedText {
                    Layout.fillWidth: true
                    text: SystemStats.osName + "  ·  " + SystemStats.wm
                    customSize: Constants.sizeSm
                    color: Theme.muted
                    elide: Text.ElideRight
                }

                ThemedText {
                    Layout.fillWidth: true
                    text: SystemStats.display
                    customSize: Constants.sizeXs + 3
                    color: Theme.muted
                    elide: Text.ElideRight
                }

            }

            RowLayout {
                spacing: Constants.sizeSm

                Rectangle {
                    implicitWidth: chooseLabel.implicitWidth + 24
                    implicitHeight: 32
                    radius: 16
                    color: chooseArea.containsMouse ? Theme.bgTertiary : Theme.bgSecondary
                    border.width: 1
                    border.color: Theme.border

                    ThemedText {
                        id: chooseLabel

                        anchors.centerIn: parent
                        text: "Choose picture"
                        customSize: Constants.sizeXs + 2
                        color: Theme.fg
                    }

                    MouseArea {
                        id: chooseArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: externalPicker.running = true
                    }

                }

                Rectangle {
                    visible: SettingsService.profileImage !== ""
                    implicitWidth: resetLabel.implicitWidth + 24
                    implicitHeight: 32
                    radius: 16
                    color: resetArea.containsMouse ? Theme.bgTertiary : Theme.bgSecondary
                    border.width: 1
                    border.color: Theme.border

                    ThemedText {
                        id: resetLabel

                        anchors.centerIn: parent
                        text: "Reset"
                        customSize: Constants.sizeXs + 2
                        color: Theme.fg
                    }

                    MouseArea {
                        id: resetArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: SettingsService.profileImage = ""
                    }

                }

            }

        }

    }

    AppGroup {
        title: "Picture"
        icon: "picture"

        ThemedTextField {
            id: pathField

            Layout.fillWidth: true
            label: "Image path"
            placeholderText: "~/Pictures/photo.jpg"
            text: SettingsService.profileImage
            onEditingFinished: root.setPicturePath(text)
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Constants.sizeSm

            Rectangle {
                implicitWidth: browseLabel.implicitWidth + 24
                implicitHeight: 32
                radius: 16
                color: browseArea.containsMouse ? Theme.bgTertiary : Theme.bgSecondary
                border.width: 1
                border.color: Theme.border

                ThemedText {
                    id: browseLabel

                    anchors.centerIn: parent
                    text: "Browse…"
                    customSize: Constants.sizeXs + 2
                    color: Theme.fg
                }

                MouseArea {
                    id: browseArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: externalPicker.running = true
                }

            }

            ThemedText {
                Layout.fillWidth: true
                text: "Type a path and press Enter, or browse with the system file chooser. The built-in picker is used when no chooser is available."
                customSize: Constants.sizeXs
                color: Theme.muted
                wrapMode: Text.WordWrap
            }

        }

    }

    AppGroup {
        title: "Account"
        icon: "apps"

        InfoRow {
            label: "Username"
            value: SystemStats.username
        }

        InfoRow {
            label: "Hostname"
            value: SystemStats.hostname
        }

        InfoRow {
            label: "Distro"
            value: SystemStats.osName
        }

        InfoRow {
            label: "Host model"
            value: SystemStats.hostModel
            visible: SystemStats.hostModel !== ""
        }

        InfoRow {
            label: "Desktop / WM"
            value: SystemStats.wm
        }

        InfoRow {
            label: "Shell"
            value: SystemStats.shell
        }

        InfoRow {
            label: "Profile picture"
            value: root.pictureLabel
        }

    }

    AppGroup {
        title: "System"
        icon: "cpu"

        InfoRow {
            label: "Kernel"
            value: SystemStats.kernel
        }

        InfoRow {
            label: "Display"
            value: SystemStats.display
        }

        InfoRow {
            label: "Packages"
            value: SystemStats.packages
        }

        InfoRow {
            label: "Processor"
            value: SystemStats.cpuModel
        }

        InfoRow {
            label: "Cores & threads"
            value: SystemStats.cpuCores
        }

        InfoRow {
            label: "Memory"
            value: SystemStats.memTotal
        }

        InfoRow {
            label: "Storage (/)"
            value: SystemStats.diskTotal
        }

        InfoRow {
            label: "Graphics"
            value: SystemStats.gpuName
            visible: SystemStats.gpuName !== "" && SystemStats.gpuName !== "None"
        }

    }

    Process {
        id: externalPicker

        command: ["python3", Quickshell.shellDir + "/Scripts/system/pick-image.py"]
        stdout: StdioCollector {
            onStreamFinished: root.setPicturePath(text)
        }
        onExited: (code) => {
            if (code !== 0 && code !== 2)
                pickerPopup.open();
        }
    }

    ListModel {
        id: imageModel
    }

    Process {
        id: imageScan

        property var lines: []

        running: false
        command: ["sh", "-c", "find \"$HOME/Pictures\" \"$HOME/.face\" /usr/share/backgrounds -maxdepth 4 -type f 2>/dev/null | grep -iE '\\.(png|jpe?g|webp|gif|bmp|svg)$' | head -400"]
        onRunningChanged: {
            if (running)
                lines = [];

        }
        onExited: {
            imageModel.clear();
            const sorted = lines.slice().sort((a, b) => {
                const ha = a.indexOf(root.home) === 0 ? 0 : 1;
                const hb = b.indexOf(root.home) === 0 ? 0 : 1;
                if (ha !== hb)
                    return ha - hb;

                return a.split("/").pop().localeCompare(b.split("/").pop());
            });
            for (let i = 0; i < sorted.length; i++)
                imageModel.append({
                    "path": sorted[i]
                });
            lines = [];
        }
        stdout: SplitParser {
            onRead: (data) => {
                const p = String(data).trim();
                if (p !== "")
                    imageScan.lines.push(p);

            }
        }

    }

    Popup {
        id: pickerPopup

        parent: Overlay.overlay
        anchors.centerIn: Overlay.overlay
        width: Math.min(680, Overlay.overlay ? Overlay.overlay.width - 80 : 680)
        height: Math.min(520, Overlay.overlay ? Overlay.overlay.height - 80 : 520)
        padding: 0
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        onOpened: imageScan.running = true
        background: Rectangle {
            color: Theme.opaqueBg
            radius: Constants.sizeLg
            border.width: 1
            border.color: Theme.border
        }

        contentItem: ColumnLayout {
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Layout.margins: Constants.sizeLg
                spacing: Constants.sizeMd

                ThemedText {
                    Layout.fillWidth: true
                    text: "Choose profile picture"
                    customSize: Constants.sizeMd
                    font.weight: Font.Bold
                    color: Theme.fg
                }

                ThemedText {
                    text: imageModel.count + " images"
                    customSize: Constants.sizeXs + 2
                    color: Theme.muted
                }

                Rectangle {
                    implicitWidth: 28
                    implicitHeight: 28
                    radius: 14
                    color: closeArea.containsMouse ? Theme.bgTertiary : "transparent"

                    ThemedText {
                        anchors.centerIn: parent
                        text: "×"
                        customSize: Constants.sizeLg
                        color: Theme.fg
                    }

                    MouseArea {
                        id: closeArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: pickerPopup.close()
                    }

                }

            }

            GridView {
                id: imageGrid

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: Constants.sizeLg
                Layout.rightMargin: Constants.sizeLg
                Layout.bottomMargin: Constants.sizeLg
                cellWidth: 158
                cellHeight: 150
                clip: true
                model: imageModel
                boundsBehavior: Flickable.StopAtBounds

                delegate: Item {
                    width: imageGrid.cellWidth
                    height: imageGrid.cellHeight

                    Rectangle {
                        id: thumbCard

                        anchors.fill: parent
                        anchors.margins: 4
                        radius: Constants.sizeSm
                        color: thumbArea.containsMouse ? Theme.bgTertiary : Theme.bg
                        border.width: 1
                        border.color: thumbArea.containsMouse ? Theme.accent : Theme.border
                        clip: true

                        Image {
                            anchors.fill: parent
                            anchors.margins: 5
                            anchors.bottomMargin: 30
                            source: "file://" + model.path
                            fillMode: Image.PreserveAspectCrop
                            sourceSize: Qt.size(144, 104)
                            asynchronous: true
                            smooth: true
                        }

                        ThemedText {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 6
                            text: model.path.split("/").pop()
                            customSize: Constants.sizeXs
                            color: Theme.muted
                            elide: Text.ElideMiddle
                        }

                        MouseArea {
                            id: thumbArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                SettingsService.profileImage = model.path;
                                pickerPopup.close();
                            }
                        }

                    }

                }

            }

            ThemedText {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: Constants.sizeLg
                horizontalAlignment: Text.AlignHCenter
                visible: imageModel.count === 0 && !imageScan.running
                text: "No images found in Pictures or the system backgrounds."
                customSize: Constants.sizeSm
                color: Theme.muted
            }

        }

    }

}
