import QtQuick
import Quickshell
import Quickshell.Io
import qs.Core
pragma Singleton

Item {
    id: updateService

    property bool isSystemUpdating: false
    property bool packageManagerChecksEnabled: true
    property int packageManagerCheckInterval: 3.6e+06
    property string pacmanUpdatesCount: "..."
    property string aurUpdatesCount: "..."
    readonly property bool isCheckingUpdates: pacmanProc.running || aurProc.running

    signal checkUpdates()

    onPackageManagerChecksEnabledChanged: {
        if (SettingsService.settingsLoaded)
            SettingsService.saveSettings();

    }
    onPackageManagerCheckIntervalChanged: {
        if (SettingsService.settingsLoaded)
            SettingsService.saveSettings();

    }
    onIsSystemUpdatingChanged: {
        if (!updateService.isSystemUpdating) {
            updateService.pacmanUpdatesCount = "...";
            updateService.aurUpdatesCount = "...";
            checkDelayTimer.start();
        }
    }
    onCheckUpdates: {
        pacmanProc.running = false;
        pacmanProc.running = true;
        aurProc.running = false;
        aurProc.running = true;
    }

    Process {
        id: pacmanProc

        // distro-agnostic: pacman (Arch), apt (Debian/Ubuntu), dnf (Fedora)
        command: ["sh", "-c", "if command -v checkupdates >/dev/null; then checkupdates 2>/dev/null | wc -l; elif command -v pacman >/dev/null; then pacman -Qu 2>/dev/null | wc -l; elif command -v apt >/dev/null; then apt list --upgradable 2>/dev/null | grep -c upgradable || true; elif command -v dnf >/dev/null; then dnf -q check-update 2>/dev/null | grep -cE '^[A-Za-z0-9_.+-]+\\.[A-Za-z0-9_]+ ' || true; else echo 0; fi"]

        stdout: SplitParser {
            onRead: (data) => {
                updateService.pacmanUpdatesCount = data.trim();
            }
        }

    }

    Process {
        id: aurProc

        command: ["sh", "-c", "if command -v paru >/dev/null; then paru -Qua 2>/dev/null | wc -l; elif command -v yay >/dev/null; then yay -Qua 2>/dev/null | wc -l; else echo 0; fi"]

        stdout: SplitParser {
            onRead: (data) => {
                updateService.aurUpdatesCount = data.trim();
            }
        }

    }

    Process {
        id: checkLockProc

        command: ["sh", "-c", "pgrep -x 'pacman|paru|yay|apt|apt-get|dpkg|aptitude|dnf' >/dev/null"]
        onExited: (code) => {
            updateService.isSystemUpdating = (code === 0);
        }
    }

    Timer {
        id: lockCheckTimer

        interval: updateService.isSystemUpdating || AppState.activeWidget === "packageManager" ? 1500 : 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            checkLockProc.running = true;
        }
    }

    Timer {
        id: hourlyUpdateTimer

        interval: updateService.packageManagerCheckInterval
        running: updateService.packageManagerChecksEnabled
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            pacmanProc.running = false;
            pacmanProc.running = true;
            aurProc.running = false;
            aurProc.running = true;
        }
    }

    Timer {
        id: checkDelayTimer

        interval: 800
        repeat: false
        onTriggered: {
            pacmanProc.running = false;
            pacmanProc.running = true;
            aurProc.running = false;
            aurProc.running = true;
        }
    }

}
