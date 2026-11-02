import QtQuick
import Quickshell
import Quickshell.Io
import qs.Core
import qs.Core.Services
pragma Singleton

QtObject {
    id: root

    property string currentWallpaper: ""
    property string currentWallpaperPath: ""
    property bool wallpaperRestored: false
    property string transitionType: HyprlandService.wpTransitionType
    property int transitionStep: HyprlandService.wpTransitionStep
    property string transitionPos: HyprlandService.wpTransitionPos
    property int transitionFps: HyprlandService.wpTransitionFps
    property int transitionAngle: HyprlandService.wpTransitionAngle
    property string resizeMode: HyprlandService.wpResizeMode
    property string cropGravity: HyprlandService.wpCropGravity
    property bool enableTransitions: HyprlandService.wpEnableTransitions
    property bool autoShuffle: HyprlandService.wpAutoShuffle
    property int shuffleInterval: HyprlandService.wpShuffleInterval
    property Process wallpaperApplyProc
    property Process wallpaperSaveProc
    property Process wallpaperLoader
    property Process randomWallpaperProc
    property Timer shuffleTimer

    readonly property string homeWallDir: Quickshell.env("HOME") + "/Pictures/Wallpapers/"

    // shell command listing every image in the configured folders (subfolders included)
    readonly property var listCommand: ["bash", "-c", "for d in \"$@\"; do case \"$d\" in '~'*) d=\"$HOME${d#'~'}\";; esac; [ -d \"$d\" ] && find -L \"$d\" -maxdepth 5 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' \\) 2>/dev/null; done | awk '!s[$0]++'", "minflair-walls"].concat(SettingsService.wallpaperDirs)

    // what gets saved: just the file name for the classic folder, the full path for everything else
    function storedName(path) {
        if (path.startsWith(homeWallDir) && path.indexOf("/", homeWallDir.length) === -1)
            return path.substring(homeWallDir.length);
        return path;
    }

    function applyWallpaperWithSync(wallpaperName, rawPath) {
        currentWallpaper = wallpaperName;
        currentWallpaperPath = rawPath;
        saveCurrentWallpaper(wallpaperName);
        applyWallpaper(rawPath);
    }

    function reapplyCurrentWallpaper() {
        let p = currentWallpaperPath;
        if (p && !p.startsWith("/"))
            p = Quickshell.env("HOME") + "/Pictures/Wallpapers/" + p;
        else if (!p && currentWallpaper)
            p = currentWallpaper.startsWith("/") ? currentWallpaper : (Quickshell.env("HOME") + "/Pictures/Wallpapers/" + currentWallpaper);
        if (p)
            applyWallpaperInstant(p);

    }

    function applyWallpaperInstant(rawPath) {
        wallpaperApplyProc.running = false;
        let rMode = HyprlandService.wpResizeMode || "crop";
        let gravity = HyprlandService.wpCropGravity || "center";
        let cmd = [Quickshell.shellDir + "/Scripts/system/awww-compat.sh", "img", rawPath, "--resize", rMode];
        if (rMode === "crop")
            cmd.push("--crop-gravity", gravity);

        cmd.push("--transition-type", "none");
        wallpaperApplyProc.command = cmd;
        wallpaperApplyProc.startDetached();
    }

    function applyWallpaper(rawPath) {
        wallpaperApplyProc.running = false;
        let rMode = HyprlandService.wpResizeMode || "crop";
        let gravity = HyprlandService.wpCropGravity || "center";
        let cmd = [Quickshell.shellDir + "/Scripts/system/awww-compat.sh", "img", rawPath, "--resize", rMode];
        if (rMode === "crop")
            cmd.push("--crop-gravity", gravity);

        if (enableTransitions && SystemInfoService.powerProfile !== "power-saver") {
            cmd.push("--transition-type", transitionType, "--transition-pos", transitionPos, "--transition-step", String(transitionStep), "--transition-fps", String(transitionFps));
            if (transitionType === "wipe" || transitionType === "wave")
                cmd.push("--transition-angle", String(transitionAngle));

            wallpaperApplyProc.command = cmd;
        } else {
            cmd.push("--transition-type", "none");
            wallpaperApplyProc.command = cmd;
        }
        wallpaperApplyProc.startDetached();
    }

    function saveCurrentWallpaper(wallName) {
        wallpaperSaveProc.running = false;
        // The wallpaper name is passed as a positional argument and written with
        // printf, so quotes, newlines or shell metacharacters in a file name can
        // never break the command or inject code.
        wallpaperSaveProc.command = ["sh", "-c", "mkdir -p \"$HOME/.cache/quickshell\" /var/tmp/minflair-greeter && printf '%s' \"$1\" > \"$HOME/.cache/quickshell/current_wallpaper\" && printf '%s' \"$1\" > /var/tmp/minflair-greeter/current_wallpaper 2>/dev/null; python3 \"$2\" 2>/dev/null || true", "minflair-wallpaper", wallName, Quickshell.shellDir + "/Scripts/theme/apply_theme.py"];
        wallpaperSaveProc.startDetached();
    }

    function shuffle() {
        randomWallpaperProc.running = false;
        randomWallpaperProc.running = true;
    }

    Component.onCompleted: {
        wallpaperLoader.running = true;
    }

    shuffleTimer: Timer {
        interval: root.shuffleInterval * 60000
        running: root.autoShuffle
        repeat: true
        onTriggered: root.shuffle()
    }

    wallpaperApplyProc: Process {
    }

    wallpaperSaveProc: Process {
    }

    randomWallpaperProc: Process {
        command: root.listCommand.concat([])
        onExited: function(exitCode) {
            if (exitCode === 0) {
                const all = randomWallOutput.text.split("\n").map(s => s.trim()).filter(s => s !== "");
                const path = all.length > 0 ? all[Math.floor(Math.random() * all.length)] : "";
                if (path) {
                    root.applyWallpaperWithSync(root.storedName(path), path);
                }
            }
        }

        stdout: StdioCollector {
            id: randomWallOutput
        }

    }

    wallpaperLoader: Process {
        command: ["cat", Quickshell.env("HOME") + "/.cache/quickshell/current_wallpaper"]
        onExited: function(exitCode) {
            if (exitCode === 0) {
                let name = wallpaperLoaderOutput.text.trim();
                if (name) {
                    root.currentWallpaper = name;
                    root.currentWallpaperPath = name.startsWith("/") ? name : (root.homeWallDir + name);
                    if (!root.wallpaperRestored) {
                        root.wallpaperRestored = true;
                        root.reapplyCurrentWallpaper();
                    }
                }
            }
        }

        stdout: StdioCollector {
            id: wallpaperLoaderOutput
        }

    }

}
