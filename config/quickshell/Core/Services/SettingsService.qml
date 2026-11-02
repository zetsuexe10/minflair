import QtQuick
import Quickshell
import Quickshell.Io
import qs.Core
pragma Singleton

Item {
    id: settingsService

    property bool settingsLoaded: false
    property string packageManagerMode: "install"
    property int clipboardMaxItems: 100
    property var enabledKbLayouts: ["us", "latam"]
    property string githubUsername: ""
    property string githubToken: ""
    property string musicPlayer: "none"
    property string musicPlayerCommand: ""
    property var availableBrowsers: []
    property string launcherBrowser: ""
    property bool isSettingsLoading: settingsLoader.running
    property string quoteCategory: "All"
    property string fontFamily: "Geist"
    property real fontScale: 1
    property real hyprScale: 1
    property bool clock24h: true
    property bool clockSeconds: false
    property bool clockShowDate: true
    property string cursorTheme: "Vimix-cursors"
    property int cursorSize: 16
    property string barStyle: "island"
    // Side bar style (third style): its own placement and options
    property string sideBarPosition: "left"
    property bool sideBarPopouts: true
    property bool sideBarWindowTitle: true
    property bool sideOsd: true
    property string weatherCity: ""            // empty: locate by IP
    property bool weatherFahrenheit: false
    // Caelestia-style desktop for the side bar: frame, bar entries, scroll actions, hover panels
    readonly property var sideBarDefaults: ({
            "frame": true,
            "border": 10,
            "rounding": 24,
            "logoImage": "",
            "mode": "amoled",
            "workspaceStyle": "numbers",
            "island": false,
            "align": "center",
            "offset": 0,
            "entries": {"logo": true, "workspaces": true, "activeWindow": true, "tray": true, "clock": true, "statusIcons": true, "power": true},
            "scroll": {"workspaces": true, "volume": true, "brightness": true},
            "hover": {"dashboard": true, "session": true, "launcher": false}
        })
    property var sideBarConfig: sideBarDefaults

    function sideCfg(group, key) {
        const c = sideBarConfig;
        if (key === undefined)
            return (c && c[group] !== undefined) ? c[group] : sideBarDefaults[group];
        const g = (c && c[group]) ? c[group] : {};
        return g[key] !== undefined ? g[key] : sideBarDefaults[group][key];
    }

    function setSideCfg(group, key, value) {
        const next = JSON.parse(JSON.stringify(sideBarConfig || {}));
        if (key === undefined) {
            next[group] = value;
        } else {
            if (!next[group])
                next[group] = {};
            next[group][key] = value;
        }
        sideBarConfig = next;
    }

    property int sideScrollStep: 5
    // folders searched for wallpapers (recursively); ~ is expanded
    property var wallpaperDirs: ["~/Pictures/Wallpapers", "/usr/share/backgrounds"]
    property int sideDashTab: 0
    readonly property var barStyles: ["island", "side"]
    readonly property var barStyleNames: ({
        "convex": "Convex",
        "island": "Island",
        "side": "Side"
    })
    property bool barIslandMode: barStyle === "island"
    property bool barConvexMode: barStyle === "convex"
    property string islandRightMode: "auto"
    property bool islandShowWorkspaces: false
    property bool islandShowTray: false
    property bool islandSinglePill: false
    readonly property int barWidgetHeight: 28
    property int numberOfWorkspaces: 10

    function saveSettings() {
        saveTimer.restart();
    }

    function load() {
        if (!settingsLoaded && !isSettingsLoading)
            settingsLoader.running = true;

    }

    function setBarStyle(style) {
        if (barStyles.indexOf(style) !== -1)
            barStyle = style;

        return barStyle;
    }

    function cycleBarStyle(step) {
        let i = barStyles.indexOf(barStyle);
        if (i < 0)
            i = 0;

        return setBarStyle(barStyles[(i + step + barStyles.length) % barStyles.length]);
    }

    function applyCursor(theme, size) {
        let t = theme !== undefined ? theme : cursorTheme;
        let s = size !== undefined ? size : cursorSize;
        applyCursorProc.command = ["python3", Quickshell.shellDir + "/Scripts/theme/apply_cursor.py", t, s.toString()];
        applyCursorProc.running = false;
        applyCursorProc.running = true;
    }

    function applyFont(font, size) {
        let f = font !== undefined ? font : fontFamily;
        let s = size !== undefined ? size : Math.round(11 * fontScale);
        applyFontProc.command = ["python3", Quickshell.shellDir + "/Scripts/theme/apply_font.py", f, s.toString()];
        applyFontProc.running = false;
        applyFontProc.running = true;
    }

    // Drops a saved browser that is no longer installed, falling back to the
    // system default instead of opening a stale command.
    function syncLauncherBrowser() {
        if (!launcherBrowser)
            return ;

        let list = availableBrowsers || [];
        if (list.length === 0)
            return ;

        for (let i = 0; i < list.length; i++) {
            if (list[i].id === launcherBrowser)
                return ;

        }
        launcherBrowser = "";
    }

    Component.onCompleted: {
        load();
        browsersProc.running = true;
    }
    onClipboardMaxItemsChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onEnabledKbLayoutsChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onGithubUsernameChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onGithubTokenChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onMusicPlayerChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onMusicPlayerCommandChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onLauncherBrowserChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onQuoteCategoryChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onFontFamilyChanged: {
        if (settingsLoaded) {
            saveSettings();
            applyFont(fontFamily, Math.round(11 * fontScale));
        }
    }
    onFontScaleChanged: {
        if (settingsLoaded) {
            saveSettings();
            applyFont(fontFamily, Math.round(11 * fontScale));
        }
    }
    onHyprScaleChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onClock24hChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onClockSecondsChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onClockShowDateChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onCursorThemeChanged: {
        if (settingsLoaded) {
            saveSettings();
            applyCursor(cursorTheme, cursorSize);
        }
    }
    onCursorSizeChanged: {
        if (settingsLoaded) {
            saveSettings();
            applyCursor(cursorTheme, cursorSize);
        }
    }
    onSideBarPositionChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onSideBarConfigChanged: {
        if (settingsLoaded)
            saveSettings();
    }
    onWeatherCityChanged: {
        if (settingsLoaded)
            saveSettings();
    }
    onWeatherFahrenheitChanged: {
        if (settingsLoaded)
            saveSettings();
    }
    onSideOsdChanged: {
        if (settingsLoaded)
            saveSettings();
    }
    onSideScrollStepChanged: {
        if (settingsLoaded)
            saveSettings();
    }
    onSideDashTabChanged: {
        if (settingsLoaded)
            saveSettings();
    }
    onSideBarPopoutsChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onSideBarWindowTitleChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onBarStyleChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onIslandRightModeChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onIslandShowWorkspacesChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onIslandShowTrayChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onIslandSinglePillChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onNumberOfWorkspacesChanged: {
        if (settingsLoaded)
            saveSettings();

    }

    Timer {
        id: saveTimer

        interval: 500
        repeat: false
        onTriggered: {
            let data = {
                "performanceInterval": SystemInfoService.performanceInterval,
                "powerProfile": SystemInfoService.powerProfile,
                "packageManagerChecksEnabled": UpdateService.packageManagerChecksEnabled,
                "packageManagerCheckInterval": UpdateService.packageManagerCheckInterval,
                "clipboardMaxItems": settingsService.clipboardMaxItems,
                "enabledKbLayouts": settingsService.enabledKbLayouts,
                "animationSpeedFactor": HyprlandService.animationSpeedFactor,
                "githubUsername": settingsService.githubUsername,
                "githubToken": settingsService.githubToken,
                "musicPlayer": settingsService.musicPlayer,
                "musicPlayerCommand": settingsService.musicPlayerCommand,
                "launcherBrowser": settingsService.launcherBrowser,
                "nightLightActive": DisplayProfileService.nightLightActive,
                "caffeineActive": DisplayProfileService.caffeineActive,
                "gameModeActive": DisplayProfileService.gameModeActive,
                "nightLightTemperature": DisplayProfileService.nightLightTemperature,
                "keyboardLayout": HyprlandService.keyboardLayout,
                "wpAutoShuffle": HyprlandService.wpAutoShuffle,
                "wpShuffleInterval": HyprlandService.wpShuffleInterval,
                "wpEnableTransitions": HyprlandService.wpEnableTransitions,
                "wpTransitionType": HyprlandService.wpTransitionType,
                "wpTransitionPos": HyprlandService.wpTransitionPos,
                "wpTransitionStep": HyprlandService.wpTransitionStep,
                "wpTransitionFps": HyprlandService.wpTransitionFps,
                "wpTransitionAngle": HyprlandService.wpTransitionAngle,
                "wpResizeMode": HyprlandService.wpResizeMode,
                "wpCropGravity": HyprlandService.wpCropGravity,
                "micMuted": AudioService.micMuted,
                "micVolume": AudioService.micVolume,
                "quoteCategory": settingsService.quoteCategory,
                "fontFamily": settingsService.fontFamily,
                "fontScale": settingsService.fontScale,
                "hyprScale": settingsService.hyprScale,
                "clock24h": settingsService.clock24h,
                "clockSeconds": settingsService.clockSeconds,
                "clockShowDate": settingsService.clockShowDate,
                "cursorTheme": settingsService.cursorTheme,
                "cursorSize": settingsService.cursorSize,
                "barStyle": settingsService.barStyle,
                "sideBarPosition": settingsService.sideBarPosition,
                "sideBarPopouts": settingsService.sideBarPopouts,
                "sideBarWindowTitle": settingsService.sideBarWindowTitle,
                "sideOsd": settingsService.sideOsd,
                "weatherCity": settingsService.weatherCity,
                "weatherFahrenheit": settingsService.weatherFahrenheit,
                "sideBarConfig": settingsService.sideBarConfig,
                "sideScrollStep": settingsService.sideScrollStep,
                "wallpaperDirs": settingsService.wallpaperDirs,
                "sideDashTab": settingsService.sideDashTab,
                "islandRightMode": settingsService.islandRightMode,
                "islandShowWorkspaces": settingsService.islandShowWorkspaces,
                "islandShowTray": settingsService.islandShowTray,
                "islandSinglePill": settingsService.islandSinglePill,
                "numberOfWorkspaces": settingsService.numberOfWorkspaces
            };
            // The greeter only reads fontFamily from its preferences file, so credentials
            // are never written to /var/tmp (it is world readable and persists
            // across reboots).
            let sddmData = {
                "fontFamily": settingsService.fontFamily
            };
            settingsSaver.running = false;
            settingsSaver.command = ["sh", "-c", "mkdir -p ~/.cache/quickshell /var/tmp/minflair-greeter && cat << 'EOF' > ~/.cache/quickshell/settings_prefs.json.tmp
" + JSON.stringify(data) + "
EOF
mv -f ~/.cache/quickshell/settings_prefs.json.tmp ~/.cache/quickshell/settings_prefs.json
chmod 600 ~/.cache/quickshell/settings_prefs.json
cat << 'EOF' > /var/tmp/minflair-greeter/settings_prefs.json.tmp
" + JSON.stringify(sddmData) + "
EOF
mv -f /var/tmp/minflair-greeter/settings_prefs.json.tmp /var/tmp/minflair-greeter/settings_prefs.json
chmod 644 /var/tmp/minflair-greeter/settings_prefs.json || true"];
            settingsSaver.running = true;
        }
    }

    Process {
        id: settingsLoader

        command: ["cat", Quickshell.env("HOME") + "/.cache/quickshell/settings_prefs.json"]
        onExited: function(exitCode) {
            if (exitCode === 0) {
                let raw = settingsOutput.text ? settingsOutput.text.trim() : "";
                if (raw.length > 0) {
                    try {
                        let prefs = JSON.parse(raw);
                        if (prefs.powerProfile !== undefined) {
                            SystemInfoService.powerProfile = prefs.powerProfile;
                            SystemInfoService.applyProfile(prefs.powerProfile);
                        } else {
                            SystemInfoService.applyProfile("balanced");
                        }
                        if (prefs.performanceInterval !== undefined)
                            SystemInfoService.performanceInterval = prefs.performanceInterval;

                        if (prefs.packageManagerChecksEnabled !== undefined)
                            UpdateService.packageManagerChecksEnabled = prefs.packageManagerChecksEnabled;

                        if (prefs.packageManagerCheckInterval !== undefined)
                            UpdateService.packageManagerCheckInterval = prefs.packageManagerCheckInterval;

                        if (prefs.clipboardMaxItems !== undefined)
                            settingsService.clipboardMaxItems = prefs.clipboardMaxItems;

                        if (prefs.animationSpeedFactor !== undefined)
                            HyprlandService.animationSpeedFactor = prefs.animationSpeedFactor;

                        if (prefs.githubUsername !== undefined)
                            settingsService.githubUsername = prefs.githubUsername;

                        if (prefs.githubToken !== undefined)
                            settingsService.githubToken = prefs.githubToken;

                        if (prefs.musicPlayer !== undefined)
                            settingsService.musicPlayer = prefs.musicPlayer;

                        if (prefs.musicPlayerCommand !== undefined)
                            settingsService.musicPlayerCommand = prefs.musicPlayerCommand;

                        if (prefs.launcherBrowser !== undefined)
                            settingsService.launcherBrowser = prefs.launcherBrowser;

                        if (prefs.nightLightActive !== undefined)
                            DisplayProfileService.nightLightActive = prefs.nightLightActive;

                        if (prefs.caffeineActive !== undefined)
                            DisplayProfileService.caffeineActive = prefs.caffeineActive;

                        if (prefs.gameModeActive !== undefined)
                            DisplayProfileService.gameModeActive = prefs.gameModeActive;

                        if (prefs.nightLightTemperature !== undefined)
                            DisplayProfileService.nightLightTemperature = prefs.nightLightTemperature;

                        if (prefs.keyboardLayout !== undefined)
                            HyprlandService.keyboardLayout = prefs.keyboardLayout;

                        if (prefs.enabledKbLayouts !== undefined)
                            settingsService.enabledKbLayouts = prefs.enabledKbLayouts;

                        if (prefs.wpAutoShuffle !== undefined)
                            HyprlandService.wpAutoShuffle = prefs.wpAutoShuffle;

                        if (prefs.wpShuffleInterval !== undefined)
                            HyprlandService.wpShuffleInterval = prefs.wpShuffleInterval;

                        if (prefs.wpEnableTransitions !== undefined)
                            HyprlandService.wpEnableTransitions = prefs.wpEnableTransitions;

                        if (prefs.wpTransitionType !== undefined)
                            HyprlandService.wpTransitionType = prefs.wpTransitionType;

                        if (prefs.wpTransitionPos !== undefined)
                            HyprlandService.wpTransitionPos = prefs.wpTransitionPos;

                        if (prefs.wpTransitionStep !== undefined)
                            HyprlandService.wpTransitionStep = prefs.wpTransitionStep;

                        if (prefs.wpTransitionFps !== undefined)
                            HyprlandService.wpTransitionFps = prefs.wpTransitionFps;

                        if (prefs.wpTransitionAngle !== undefined)
                            HyprlandService.wpTransitionAngle = prefs.wpTransitionAngle;

                        if (prefs.wpResizeMode !== undefined)
                            HyprlandService.wpResizeMode = prefs.wpResizeMode;

                        if (prefs.wpCropGravity !== undefined)
                            HyprlandService.wpCropGravity = prefs.wpCropGravity;

                        if (prefs.micVolume !== undefined && AudioService.hasPhysicalMic)
                            AudioService.setMicVolume(prefs.micVolume);

                        if (prefs.micMuted !== undefined && AudioService.hasPhysicalMic)
                            AudioService.setMicMuted(prefs.micMuted);

                        if (prefs.quoteCategory !== undefined)
                            settingsService.quoteCategory = prefs.quoteCategory;

                        if (prefs.fontFamily !== undefined)
                            settingsService.fontFamily = prefs.fontFamily;

                        if (prefs.fontScale !== undefined)
                            settingsService.fontScale = prefs.fontScale;

                        if (prefs.hyprScale !== undefined) {
                            settingsService.hyprScale = prefs.hyprScale;
                            hyprScaleApplyProc.running = true;
                        }
                        if (prefs.clock24h !== undefined)
                            settingsService.clock24h = prefs.clock24h;

                        if (prefs.clockSeconds !== undefined)
                            settingsService.clockSeconds = prefs.clockSeconds;

                        if (prefs.clockShowDate !== undefined)
                            settingsService.clockShowDate = prefs.clockShowDate;

                        if (prefs.cursorTheme !== undefined)
                            settingsService.cursorTheme = prefs.cursorTheme;

                        if (prefs.cursorSize !== undefined)
                            settingsService.cursorSize = prefs.cursorSize;

                        applyCursor(settingsService.cursorTheme, settingsService.cursorSize);
                        applyFont(settingsService.fontFamily, Math.round(11 * settingsService.fontScale));
                        if (prefs.barStyle !== undefined) {
                            if (settingsService.barStyles.indexOf(prefs.barStyle) !== -1)
                                settingsService.barStyle = prefs.barStyle;
                            else
                                settingsService.barStyle = "island";
                        }
                        if (["left", "right", "top", "bottom"].indexOf(prefs.sideBarPosition) !== -1)
                            settingsService.sideBarPosition = prefs.sideBarPosition;

                        if (prefs.sideBarPopouts !== undefined)
                            settingsService.sideBarPopouts = prefs.sideBarPopouts;

                        if (prefs.sideBarWindowTitle !== undefined)
                            settingsService.sideBarWindowTitle = prefs.sideBarWindowTitle;

                        if (prefs.sideBarConfig && typeof prefs.sideBarConfig === "object")
                            settingsService.sideBarConfig = prefs.sideBarConfig;

                        if (typeof prefs.weatherCity === "string")
                            settingsService.weatherCity = prefs.weatherCity;

                        if (prefs.weatherFahrenheit !== undefined)
                            settingsService.weatherFahrenheit = prefs.weatherFahrenheit;

                        if (prefs.sideOsd !== undefined)
                            settingsService.sideOsd = prefs.sideOsd;

                        if (Array.isArray(prefs.wallpaperDirs))
                            settingsService.wallpaperDirs = prefs.wallpaperDirs;
                        if (prefs.sideScrollStep !== undefined)
                            settingsService.sideScrollStep = Math.max(1, Math.min(20, prefs.sideScrollStep));

                        if (prefs.sideDashTab !== undefined)
                            settingsService.sideDashTab = Math.max(0, Math.min(3, prefs.sideDashTab));

                        if (prefs.islandRightMode !== undefined)
                            settingsService.islandRightMode = prefs.islandRightMode;

                        if (prefs.islandShowWorkspaces !== undefined)
                            settingsService.islandShowWorkspaces = prefs.islandShowWorkspaces;

                        if (prefs.islandShowTray !== undefined)
                            settingsService.islandShowTray = prefs.islandShowTray;

                        if (prefs.islandSinglePill !== undefined)
                            settingsService.islandSinglePill = prefs.islandSinglePill;

                        if (prefs.numberOfWorkspaces !== undefined)
                            settingsService.numberOfWorkspaces = prefs.numberOfWorkspaces;

                    } catch (e) {
                        console.error("Error loading settings: " + e);
                        SystemInfoService.applyProfile("balanced");
                    }
                } else {
                    SystemInfoService.applyProfile("balanced");
                    settingsService.saveSettings();
                }
            } else {
                SystemInfoService.applyProfile("balanced");
                settingsService.saveSettings();
                settingsService.applyCursor(settingsService.cursorTheme, settingsService.cursorSize);
                settingsService.applyFont(settingsService.fontFamily, Math.round(11 * settingsService.fontScale));
            }
            settingsService.settingsLoaded = true;
            settingsService.syncLauncherBrowser();
            HyprlandService.triggerStartupTimer();
        }

        stdout: StdioCollector {
            id: settingsOutput
        }

    }

    Process {
        id: settingsSaver
    }

    Process {
        id: browsersProc

        command: ["python3", Quickshell.shellDir + "/Modules/Launcher/scripts/get_browsers.py"]
        onExited: function(exitCode) {
            if (exitCode !== 0)
                return ;

            try {
                let parsed = JSON.parse(browsersOutput.text ? browsersOutput.text.trim() : "[]");
                if (Array.isArray(parsed)) {
                    settingsService.availableBrowsers = parsed;
                    settingsService.syncLauncherBrowser();
                }
            } catch (e) {
                console.error("Error parsing browsers JSON: " + e);
            }
        }

        stdout: StdioCollector {
            id: browsersOutput
        }

    }

    Process {
        id: hyprScaleApplyProc

        command: ["sh", "-c", "\"$1\" \"$2\"", "minflair-hypr-scale", Quickshell.shellDir + "/Scripts/system/hypr_scale.sh", "" + settingsService.hyprScale]
    }

    Process {
        id: applyCursorProc
    }

    Process {
        id: applyFontProc
    }

}
