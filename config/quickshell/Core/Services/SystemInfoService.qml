import QtQuick
import Quickshell
import Quickshell.Io
import qs.Core
pragma Singleton

Item {
    id: systemInfoService

    property int performanceInterval: 2000
    property string powerProfile: "balanced"
    property bool hasPerformanceProfile: true
    property date currentTime: systemClock.date
    property string osId: "arch"
    property string osPretty: ""
    property string osLike: ""
    property string osLogoName: ""
    property string osIssue: ""
    // branding shown to the user: the override from settings, then /etc/issue when a derivative
    // brands itself there (os-release often still says Debian/Arch), then os-release itself
    readonly property string issueBrand: {
        const s = osIssue.replace(/\\[a-zA-Z]/g, "").replace(/\s+/g, " ").trim();
        if (s === "")
            return "";
        const base = ([osId, osPretty.split(" ")[0]].concat(osLike.split(" "))).filter(w => w !== "").map(w => w.toLowerCase());
        const low = s.toLowerCase();
        return base.some(w => low.indexOf(w) === 0) ? "" : s;
    }
    readonly property string osName: {
        if (SettingsService.osNameOverride !== "")
            return SettingsService.osNameOverride;
        if (issueBrand !== "")
            return issueBrand;
        if (osPretty !== "")
            return osPretty;
        switch (osId) {
        case "endeavouros":
            return "EndeavourOS";
        case "manjaro":
        case "manjaro-arm":
            return "Manjaro";
        case "garuda":
            return "Garuda Linux";
        case "arcolinux":
            return "ArcoLinux";
        case "cachyos":
            return "CachyOS";
        case "artix":
            return "Artix Linux";
        default:
            return "Arch Linux";
        }
    }
    property bool hasBattery: true
    property int batteryLevel: 100
    readonly property string batteryPercentage: batteryLevel + "%"
    property string batteryStatus: ""
    property string batteryEstimation: {
        if (!hasBattery)
            return "Continuous power supply active";

        if (batteryStatus === "Charging")
            return "Charging";
        else if (batteryStatus === "Discharging")
            return "Discharging";
        else if (batteryStatus === "Full")
            return "Fully Charged";
        else if (batteryStatus === "Not charging")
            return "Not charging";
        else
            return "Stationary";
    }
    property bool isPluggedIn: false
    property bool _powerInitialized: false
    property bool _fullNotified: false

    function applyProfile(profile) {
        let targetProfile = profile;
        systemInfoService.powerProfile = targetProfile;
        setPowerProfileProc.running = false;
        setPowerProfileProc.command = ["powerprofilesctl", "set", targetProfile];
        setPowerProfileProc.running = true;
        if (targetProfile === "performance") {
            systemInfoService.performanceInterval = 1000;
            HyprlandService.enableAnimations = true;
            if (SettingsService.settingsLoaded)
                HyprlandService.setPowerSaverMode(false);

        } else if (targetProfile === "power-saver") {
            systemInfoService.performanceInterval = 5000;
            HyprlandService.enableAnimations = false;
            if (SettingsService.settingsLoaded)
                HyprlandService.setPowerSaverMode(true);

            DisplayProfileService.caffeineActive = false;
        } else {
            systemInfoService.performanceInterval = 2000;
            HyprlandService.enableAnimations = true;
            if (SettingsService.settingsLoaded)
                HyprlandService.setPowerSaverMode(false);

        }
        if (SettingsService.settingsLoaded)
            SettingsService.saveSettings();

    }

    onPerformanceIntervalChanged: {
        if (SettingsService.settingsLoaded)
            SettingsService.saveSettings();

    }

    SystemClock {
        id: systemClock

        precision: SettingsService.clockSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }

    Process {
        id: setPowerProfileProc
    }

    Process {
        id: osReleaseProc

        command: ["sh", "-c", ". /etc/os-release 2>/dev/null; printf '%s\\n%s\\n%s\\n%s\\n%s\\n' \"$ID\" \"${PRETTY_NAME:-$NAME}\" \"$ID_LIKE\" \"$LOGO\" \"$(head -n1 /etc/issue 2>/dev/null)\""]
        running: true
        onExited: (exitCode) => {
            if (exitCode === 0) {
                let lines = osOutput.text.split("\n");
                let id = (lines[0] || "").trim();
                if (id !== "")
                    systemInfoService.osId = id;

                systemInfoService.osPretty = (lines[1] || "").trim();
                systemInfoService.osLike = (lines[2] || "").trim();
                systemInfoService.osLogoName = (lines[3] || "").trim();
                systemInfoService.osIssue = (lines[4] || "").trim();

            }
        }

        stdout: StdioCollector {
            id: osOutput
        }

    }

    Process {
        id: batteryProc

        command: ["sh", "-c", 'cap=0; stat="Unknown"; ac=0; for p in /sys/class/power_supply/*; do [ ! -d "$p" ] && continue; t=$(cat "$p/type" 2>/dev/null); if [ "$t" = "Mains" ] || [ "$t" = "USB" ] || [ "$t" = "AC" ]; then [ "$(cat "$p/online" 2>/dev/null)" = "1" ] && ac=1; elif [ "$t" = "Battery" ] || [ -f "$p/capacity" ]; then [ -f "$p/present" ] && [ "$(cat "$p/present" 2>/dev/null)" = "0" ] && continue; c=$(cat "$p/capacity" 2>/dev/null); s=$(cat "$p/status" 2>/dev/null); [ -n "$c" ] && cap=$c; [ -n "$s" ] && stat=$s; fi; done; [ "$cap" = "0" ] && [ "$stat" = "Unknown" ] && stat="No battery"; echo "$cap|$stat|$ac"']

        stdout: SplitParser {
            onRead: (data) => {
                let parts = data.trim().split("|");
                if (parts.length >= 3) {
                    let capacity = parseInt(parts[0]);
                    let status = parts[1];
                    let acVal = parseInt(parts[2]);
                    let plugged = (acVal === 1 || status === "Charging");
                    let level = isNaN(capacity) ? 0 : Math.min(100, Math.max(0, capacity));
                    systemInfoService.batteryLevel = level;
                    systemInfoService.batteryStatus = status;
                    systemInfoService.hasBattery = (parts[0] !== "0" || status !== "No battery");
                    if (systemInfoService.hasBattery) {
                        let isFull = plugged && (status === "Full" || (status === "Not charging" && level >= 95) || level >= 100);
                        if (!systemInfoService._powerInitialized) {
                            systemInfoService.isPluggedIn = plugged;
                            systemInfoService._powerInitialized = true;
                            if (isFull)
                                systemInfoService._fullNotified = true;

                        } else if (systemInfoService.isPluggedIn !== plugged) {
                            systemInfoService.isPluggedIn = plugged;
                            if (plugged) {
                                OsdService.displayMessage("Charger Connected", systemInfoService.batteryPercentage, "charger-filled", true);
                                if (isFull)
                                    systemInfoService._fullNotified = true;

                            } else {
                                systemInfoService._fullNotified = false;
                                OsdService.displayMessage("Charger Disconnected", systemInfoService.batteryPercentage, "charger", false);
                            }
                        } else if (isFull && !systemInfoService._fullNotified) {
                            systemInfoService._fullNotified = true;
                            OsdService.displayMessage("Battery Full", systemInfoService.batteryPercentage, "charger-filled", true);
                        } else if (!isFull && level < 95) {
                            systemInfoService._fullNotified = false;
                        }
                    }
                }
            }
        }

    }

    Timer {
        id: powerDebounceTimer

        interval: 150
        repeat: false
        onTriggered: {
            batteryProc.running = false;
            batteryProc.running = true;
        }
    }

    Process {
        id: powerUeventProc

        command: ["sh", "-c", "exec udevadm monitor -u -s power_supply 2>/dev/null"]
        running: true

        stdout: SplitParser {
            onRead: (data) => {
                powerDebounceTimer.restart();
            }
        }

    }

    Timer {
        id: batteryTimer

        // powerUeventProc already refreshes the battery on every power_supply
        // uevent, so this timer is only a slow safety net. Polling here at
        // performanceInterval forked a shell script every second for nothing.
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!powerDebounceTimer.running && !batteryProc.running)
                batteryProc.running = true;

        }
    }

}
