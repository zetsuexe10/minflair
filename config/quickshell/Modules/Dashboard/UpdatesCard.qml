import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Dashboard.Components

Card {
    id: root

    property var widget: null
    readonly property string pacmanUpdates: UpdateService.pacmanUpdatesCount
    readonly property string aurUpdates: UpdateService.aurUpdatesCount
    property bool hasUpdates: (parseInt(pacmanUpdates) > 0 || parseInt(aurUpdates) > 0)
    readonly property bool isChecking: UpdateService.isCheckingUpdates
    readonly property bool isUpdating: UpdateService.isSystemUpdating

    function runUpdate() {
        const upd = "if command -v paru >/dev/null; then paru -Syu; elif command -v yay >/dev/null; then yay -Syu; elif command -v pacman >/dev/null; then sudo pacman -Syu; elif command -v apt >/dev/null; then sudo apt update && sudo apt full-upgrade; elif command -v dnf >/dev/null; then sudo dnf upgrade; fi; echo; echo Done. Press Enter.; read _";
        Quickshell.execDetached(["sh", "-c", "t=${TERMINAL:-}; for c in \"$t\" kitty foot alacritty wezterm konsole gnome-terminal x-terminal-emulator xterm; do [ -n \"$c\" ] && command -v \"$c\" >/dev/null && { exec \"$c\" -e sh -c \"$1\"; }; done", "sh", upd]);
    }

    contentPadding: Constants.sizeMd
    implicitHeight: contentCol.implicitHeight + root.contentPadding * 2

    ColumnLayout {
        id: contentCol

        anchors.fill: parent
        spacing: Constants.sizeXs

        RowLayout {
            Layout.fillWidth: true
            spacing: Constants.sizeSm

            ThemedText {
                text: "System Updates"
                customSize: Constants.sizeMd
                font.bold: true
                color: Theme.fg
            }

            Item {
                Layout.fillWidth: true
            }

            Rectangle {
                visible: root.hasUpdates && !root.isUpdating && !root.isChecking
                color: Theme.bgSecondary
                radius: height / 2
                implicitWidth: updateCountText.implicitWidth + 12
                implicitHeight: Constants.sizeLg + 2

                ThemedText {
                    id: updateCountText

                    anchors.centerIn: parent
                    text: {
                        let total = (parseInt(root.pacmanUpdates) || 0) + (parseInt(root.aurUpdates) || 0);
                        return total + " NEW";
                    }
                    customSize: Constants.sizeXs + 1
                    font.bold: true
                    color: Theme.accent
                }

            }

        }

        Divider {
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Constants.sizeMd

            RowLayout {
                spacing: Constants.sizeSm
                Layout.fillWidth: true

                SvgIcon {
                    id: statusIcon

                    icon: {
                        if (root.isUpdating || root.isChecking)
                            return "reload";

                        return root.hasUpdates ? "update" : "check";
                    }
                    flat: true
                    iconColor: {
                        if (root.isUpdating)
                            return Theme.accent;

                        if (root.isChecking)
                            return Theme.muted;

                        return Theme.accent;
                    }

                    RotationAnimation on rotation {
                        from: 0
                        to: 360
                        duration: Constants.animExpressive * 2
                        loops: Animation.Infinite
                        running: (root.isUpdating || root.isChecking) && Constants.durationFactor > 0
                        onRunningChanged: {
                            if (!running)
                                statusIcon.rotation = 0;

                        }
                    }

                }

                ColumnLayout {
                    spacing: Constants.size3Xs
                    Layout.fillWidth: true

                    ThemedText {
                        text: {
                            if (root.isUpdating)
                                return "Updating system...";

                            if (root.isChecking)
                                return "Checking updates...";

                            if (root.pacmanUpdates === "..." || root.aurUpdates === "...")
                                return "Checking updates...";

                            let total = (parseInt(root.pacmanUpdates) || 0) + (parseInt(root.aurUpdates) || 0);
                            return total > 0 ? total + " packages pending" : "System up to date";
                        }
                        font.bold: true
                        color: Theme.fg
                    }

                    ThemedText {
                        text: {
                            if (root.isUpdating || root.isChecking || root.pacmanUpdates === "...")
                                return "Please wait";

                            let total = (parseInt(root.pacmanUpdates) || 0) + (parseInt(root.aurUpdates) || 0);
                            if (total > 0)
                                return "Updates: " + (parseInt(root.pacmanUpdates) || 0) + ((parseInt(root.aurUpdates) || 0) > 0 ? " + " + root.aurUpdates + " AUR" : "");

                            return "All packages are currently up to date";
                        }
                        customSize: Constants.sizeXs + 1
                        color: Theme.muted
                    }

                }

            }

            Item {
                Layout.fillWidth: true
            }

            ThemedButton {
                id: updateButton

                text: root.hasUpdates && !root.isUpdating ? "Update" : "Check"
                onClicked: {
                    if (root.hasUpdates && !root.isUpdating)
                        root.runUpdate();
                    else
                        UpdateService.checkUpdates();
                }

                SequentialAnimation on scale {
                    running: (root.widget ? root.widget.isOpen : true) && root.hasUpdates && !root.isUpdating
                    loops: 3

                    PropertyAnimation {
                        to: 1.04
                        duration: Constants.animUltraSlow * 2
                        easing.type: Easing.InOutQuad
                    }

                    PropertyAnimation {
                        to: 1
                        duration: Constants.animUltraSlow * 2
                        easing.type: Easing.InOutQuad
                    }

                }

            }

        }

    }

}
