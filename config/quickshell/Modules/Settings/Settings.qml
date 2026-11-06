import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Core.Windows
import qs.Modules.Settings.Components
import qs.Modules.Settings.EffectsSettings
import qs.Modules.Settings.InputAndClipboardSettings
import qs.Modules.Settings.IntegrationsSettings
import qs.Modules.Settings.MouseSettings
import qs.Modules.Settings.PersonalizationSettings
import qs.Modules.Settings.ProfileSettings
import qs.Modules.Settings.SystemInfo
import qs.Modules.Settings.WallpaperSettings
import qs.Modules.Settings.WindowSettings

AppWindow {
    id: root

    property int page: 0
    property string query: ""
    readonly property string q: query.trim().toLowerCase()
    readonly property var currentPage: pages[page] || pages[0]
    readonly property bool searching: q !== ""

    readonly property var styleOptions: [{ "text": "Convex", "value": "convex" }, { "text": "Island", "value": "island" }, { "text": "Side", "value": "side" }, { "text": "Dynamic", "value": "dynamic" }]
    readonly property var positionOptions: [{ "text": "Left", "value": "left" }, { "text": "Right", "value": "right" }, { "text": "Top", "value": "top" }, { "text": "Bottom", "value": "bottom" }]
    readonly property var wsStyleOptions: [{ "text": "Numbers", "value": "numbers" }, { "text": "Shapes", "value": "shapes" }, { "text": "App icons", "value": "icons" }]
    readonly property var placeOptions: [{ "text": "Start", "value": "start" }, { "text": "Centre", "value": "center" }, { "text": "End", "value": "end" }]
    readonly property var modeOptions: [{ "text": "AMOLED", "value": "amoled" }, { "text": "Dark", "value": "dark" }, { "text": "Light", "value": "light" }, { "text": "Theme", "value": "auto" }]
    readonly property var unitOptions: [{ "text": "°C", "value": false }, { "text": "°F", "value": true }]
    readonly property var dashTabOptions: [{ "text": "Dashboard", "value": 0 }, { "text": "Media", "value": 1 }, { "text": "Performance", "value": 2 }, { "text": "Weather", "value": 3 }]
    readonly property var dynIdleOptions: [{ "text": "Automatic (music when playing, else time)", "value": "auto" }, { "text": "Time", "value": "time" }, { "text": "Music", "value": "media" }, { "text": "Notifications", "value": "notifications" }]
    readonly property var islandRightOptions: [{ "text": "Auto", "value": "auto" }, { "text": "Music", "value": "music" }, { "text": "Control centre", "value": "control_center" }]

    readonly property var clockRows: [
        { "kind": "toggle", "label": "24-hour time", "desc": "Use 24-hour time instead of AM/PM", "prop": "clock24h" },
        { "kind": "toggle", "label": "Show seconds", "desc": "Display seconds on the clock", "prop": "clockSeconds" },
        { "kind": "toggle", "label": "Show date", "desc": "Display the date next to the time", "prop": "clockShowDate" }
    ]
    readonly property var layoutParts: [{ "key": "logo", "label": "Launcher button" }, { "key": "workspaces", "label": "Workspaces" }, { "key": "activeWindow", "label": "Active window" }, { "key": "music", "label": "Now playing" }, { "key": "tray", "label": "System tray" }, { "key": "statusIcons", "label": "Status icons" }, { "key": "clock", "label": "Clock" }, { "key": "power", "label": "Power button" }]
    readonly property var layoutRows: {
        const out = [];
        for (let i = 0; i < layoutParts.length; i++) {
            const p = layoutParts[i];
            out.push({ "kind": "select", "label": p.label, "desc": "Which part of the bar it sits in", "cfg": ["place", p.key], "options": placeOptions });
            out.push({ "kind": "stepper", "label": p.label + " order", "desc": "Position within that part, lowest first", "cfg": ["order", p.key], "from": 1, "to": 9, "step": 1 });
        }
        return out;
    }
    readonly property var workspaceRows: [
        { "kind": "stepper", "label": "Number of workspaces", "desc": "Total shown on the bar; it follows the active one", "prop": "numberOfWorkspaces", "from": 1, "to": 20, "step": 1 }
    ]

    readonly property var pages: root.buildPages()

    function buildPages() {
        return [
            { "key": "profile", "title": "Profile", "icon": "apps", "section": "PROFILE", "sub": "Account, host, distro and lock screen picture", "component": profileComp },

            { "key": "appearance", "title": "Appearance", "icon": "color-palette", "section": "DESKTOP", "sub": "Themes, palette, dynamic colors and shell typography", "component": personalizationComp },
            { "key": "wallpaper", "title": "Wallpaper", "icon": "picture", "section": "DESKTOP", "sub": "Folders, crop preview and scaling", "component": wallpaperComp },
            { "key": "bar", "title": "Bar", "icon": "bar", "section": "DESKTOP", "sub": "Active style, clock and workspaces shared by every bar", "sections": [
                { "name": "Style", "rows": [
                    { "kind": "select", "label": "Bar style", "desc": "Super+Alt+1..4 switches directly; Super+Alt+B cycles", "prop": "barStyle", "options": root.styleOptions },
                    { "kind": "info", "label": "Active style", "desc": "", "text": SettingsService.barStyleNames[SettingsService.barStyle] || SettingsService.barStyle }
                ] },
                { "name": "Per-bar settings", "rows": [
                    { "kind": "button", "label": "Convex (bar 1)", "desc": "", "action": "gotoPage", "page": "convex", "value": "Open" },
                    { "kind": "button", "label": "Island (bar 2)", "desc": "", "action": "gotoPage", "page": "island", "value": "Open" },
                    { "kind": "button", "label": "Side (bar 3)", "desc": "", "action": "gotoPage", "page": "side", "value": "Open" },
                    { "kind": "button", "label": "Dynamic (bar 4)", "desc": "", "action": "gotoPage", "page": "dynamic", "value": "Open" }
                ] },
                { "name": "Clock (all bars)", "rows": root.clockRows },
                { "name": "Workspaces (all bars)", "rows": root.workspaceRows }
            ] },
            { "key": "panels", "title": "Panels", "icon": "widgets", "section": "DESKTOP", "sub": "Hover panels, dashboard, on-screen display and weather", "sections": [
                { "name": "Dashboard", "rows": [
                    { "kind": "select", "label": "Opens on", "desc": "Tab shown when the dashboard opens", "prop": "sideDashTab", "options": root.dashTabOptions },
                    { "kind": "text", "label": "OS name", "desc": "Shown on the dashboard. Empty detects it from os-release", "prop": "osNameOverride", "placeholder": "FlickOS" },
                    { "kind": "text", "label": "Dashboard logo", "desc": "PNG, SVG or JPG shown in the round avatar. Empty uses ~/.face, then the distro logo", "cfg": ["logoImage"], "placeholder": "~/Pictures/logo.png" },
                    { "kind": "button", "label": "Choose logo", "desc": "Pick a file from a dialog", "action": "browseLogo", "value": "Browse" },
                    { "kind": "button", "label": "Reset logo", "desc": "Back to ~/.face or the distro logo", "action": "resetLogo", "value": "Reset" }
                ] },
                { "name": "On-screen display", "rows": [
                    { "kind": "stepper", "label": "Hide after", "desc": "How long the sliders stay once you stop changing the value", "prop": "osdHideDelay", "from": 500, "to": 6000, "step": 100, "suffix": " ms" },
                    { "kind": "toggle", "label": "Microphone slider", "desc": "Add a third slider for the microphone", "prop": "osdMicrophone" },
                    { "kind": "toggle", "label": "Built-in Side bar indicator", "desc": "Used on the Side bar only while its edge sliders are turned off", "prop": "sideOsd" },
                    { "kind": "info", "label": "Per bar", "desc": "", "text": "Turn the sliders on or off on each bar's page" }
                ] },
                { "name": "Weather", "rows": [
                    { "kind": "text", "label": "City", "desc": "Leave empty to locate by IP address", "prop": "weatherCity", "placeholder": "Lisbon" },
                    { "kind": "select", "label": "Units", "desc": "Temperature and wind speed", "prop": "weatherFahrenheit", "options": root.unitOptions },
                    { "kind": "info", "label": "Status", "desc": "", "info": "weather" }
                ] }
            ] },
            { "key": "effects", "title": "Visual Effects", "icon": "sparkles", "section": "DESKTOP", "sub": "Blur, opacity, window animations and shadows", "component": effectsComp },
            { "key": "windows", "title": "Windows & Display", "icon": "monitor", "section": "DESKTOP", "sub": "Window rules, borders, gaps and monitors", "component": windowComp },

            { "key": "convex", "title": "Convex (bar 1)", "icon": "bar", "section": "BARS", "sub": "The classic curved top bar", "sections": [
                { "name": "Layout", "rows": [
                    { "kind": "info", "label": "Bar", "desc": "", "text": "Top edge, curved centre" },
                    { "kind": "info", "label": "Workspaces", "desc": "", "text": "Left, with the focused window" },
                    { "kind": "info", "label": "Clock", "desc": "", "text": "Centre pill" },
                    { "kind": "info", "label": "Status", "desc": "", "text": "Tray and status icons on the right" },
                    { "kind": "button", "label": "Clock and workspaces", "desc": "Shared by every bar", "action": "gotoPage", "page": "bar", "value": "Open" }
                ] },
            ] },
            { "key": "island", "title": "Island (bar 2)", "icon": "box", "section": "BARS", "sub": "The expanding top-centre island", "sections": [
                { "name": "Island", "rows": [
                    { "kind": "toggle", "label": "Single island", "desc": "Only the centre pill: star, clock and media. Hides workspaces and tray", "prop": "islandSinglePill" },
                    { "kind": "select", "label": "Right circular island", "desc": "What the right island shows", "prop": "islandRightMode", "options": root.islandRightOptions },
                    { "kind": "toggle", "label": "Show workspaces", "desc": "Interactive workspace indicators on the left", "prop": "islandShowWorkspaces" },
                    { "kind": "toggle", "label": "Show system tray", "desc": "Tray icons on the right", "prop": "islandShowTray" }
                ] },
                { "name": "On-screen display", "rows": [
                    { "kind": "toggle", "label": "Volume and brightness sliders", "desc": "Right-edge sliders: appear when volume or brightness changes, or when you hover the right edge", "osd": "island" }
                ] },
            ] },
            { "key": "side", "title": "Side (bar 3)", "icon": "layout-filled", "section": "BARS", "sub": "Frame bar, dynamic mode, entries and scrolling", "sections": [
                { "name": "Position", "rows": [
                    { "kind": "select", "label": "Edge", "desc": "Which screen edge the bar sits on", "prop": "sideBarPosition", "options": root.positionOptions }
                ] },
                { "name": "Dynamic mode", "rows": [
                    { "kind": "toggle", "label": "Dynamic bar", "desc": "The bar shrinks to workspaces, the clock and the song playing, and grows back when you hover it", "cfg": ["dynamic"] },
                    { "kind": "toggle", "label": "Expand on hover", "desc": "Off: click the small bar to expand it", "cfg": ["hover", "dynamic"] },
                    { "kind": "toggle", "label": "Keep expanded", "desc": "Always show the whole bar", "cfg": ["pinned"] },
                    { "kind": "toggle", "label": "Music card on hover", "desc": "Hover the song to open the player; click to open or close", "cfg": ["hover", "music"] }
                ] },
                { "name": "Entries", "rows": [
                    { "kind": "toggle", "label": "Launcher button", "desc": "Opens the launcher", "cfg": ["entries", "logo"] },
                    { "kind": "toggle", "label": "Workspaces", "desc": "Workspace switcher", "cfg": ["entries", "workspaces"] },
                    { "kind": "select", "label": "Workspace style", "desc": "Shapes (Caelestia), numbers, or app icons", "cfg": ["workspaceStyle"], "options": root.wsStyleOptions },
                    { "kind": "toggle", "label": "Active window", "desc": "Title of the focused window", "cfg": ["entries", "activeWindow"] },
                    { "kind": "toggle", "label": "Window title text", "desc": "Show the title text on the bar", "prop": "sideBarWindowTitle" },
                    { "kind": "toggle", "label": "Now playing", "desc": "The song that is playing, with its cover", "cfg": ["entries", "music"] },
                    { "kind": "toggle", "label": "System tray", "desc": "Tray icons", "cfg": ["entries", "tray"] },
                    { "kind": "toggle", "label": "Status icons", "desc": "Network, Bluetooth, volume, brightness, keyboard, notifications", "cfg": ["entries", "statusIcons"] },
                    { "kind": "toggle", "label": "Clock", "desc": "Date and time", "cfg": ["entries", "clock"] },
                    { "kind": "toggle", "label": "Power button", "desc": "Hover or click opens the power panel", "cfg": ["entries", "power"] }
                ] },
                { "name": "Hover panels", "rows": [
                    { "kind": "toggle", "label": "Power panel", "desc": "Hover the power button on the bar", "cfg": ["hover", "session"] },
                    { "kind": "toggle", "label": "Dashboard", "desc": "Hover the top edge, centre", "cfg": ["hover", "dashboard"] },
                    { "kind": "toggle", "label": "Launcher", "desc": "Hover the bottom edge, centre", "cfg": ["hover", "launcher"] }
                ] },
                { "name": "Popouts and scrolling", "rows": [
                    { "kind": "toggle", "label": "Hover popouts", "desc": "Open the Wi-Fi, Bluetooth, sound, calendar and notification panels from their icons", "prop": "sideBarPopouts" },
                    { "kind": "toggle", "label": "Scroll workspaces", "desc": "Scroll over the workspaces to switch", "cfg": ["scroll", "workspaces"] },
                    { "kind": "toggle", "label": "Scroll volume", "desc": "Scroll the first half of the bar", "cfg": ["scroll", "volume"] },
                    { "kind": "toggle", "label": "Scroll brightness", "desc": "Scroll the second half of the bar", "cfg": ["scroll", "brightness"] },
                    { "kind": "stepper", "label": "Scroll step", "desc": "Percent per notch for volume and brightness", "prop": "sideScrollStep", "from": 1, "to": 20, "step": 1, "suffix": "%" }
                ] },
                { "name": "More", "rows": [
                    { "kind": "button", "label": "Layout", "desc": "Choose which part of the bar each entry sits in and in what order", "action": "gotoPage", "page": "sidelayout", "value": "Open" },
                    { "kind": "button", "label": "Frame and colours", "desc": "Screen frame, border, rounding and colour mode", "action": "gotoPage", "page": "sideframe", "value": "Open" }
                ] }
            ] },
            { "key": "sidelayout", "title": "Side · Layout", "icon": "layout-filled", "section": "BARS", "sub": "Where each entry sits on the Side bar", "sections": [
                { "name": "Placement and order", "rows": root.layoutRows },
                { "name": "Reset", "rows": [
                    { "kind": "button", "label": "Reset the Side bar", "desc": "Back to the default entries, layout, frame and colours", "action": "resetSide", "value": "Reset" }
                ] }
            ] },
            { "key": "sideframe", "title": "Side · Frame", "icon": "layout-filled", "section": "BARS", "sub": "Screen frame and colour mode of the Side bar", "sections": [
                { "name": "Frame and colours", "rows": [
                    { "kind": "toggle", "label": "Screen frame", "desc": "Border around the screen with rounded inner corners", "cfg": ["frame"] },
                    { "kind": "stepper", "label": "Border thickness", "desc": "Width of the frame on edges without the bar", "cfg": ["border"], "from": 4, "to": 24, "step": 1, "suffix": " px" },
                    { "kind": "stepper", "label": "Corner rounding", "desc": "Radius of the inner corners and panels", "cfg": ["rounding"], "from": 0, "to": 48, "step": 2, "suffix": " px" },
                    { "kind": "select", "label": "Mode", "desc": "AMOLED is pure black; the Side bar and its panels follow it", "cfg": ["mode"], "options": root.modeOptions }
                ] }
            ] },
            { "key": "dynamic", "title": "Dynamic (bar 4)", "icon": "widgets", "section": "BARS", "sub": "Top-centre pill, orbs and island views", "sections": [
                { "name": "Behaviour", "rows": [
                    { "kind": "toggle", "label": "Music button", "desc": "Round music button beside the pill; click it to open the player", "dyn": ["musicButton"] },
                    { "kind": "toggle", "label": "Hover peek", "desc": "Hover the pill to peek at the song instead of the current view", "dyn": ["glance"] },
                    { "kind": "toggle", "label": "Swipe and scroll", "desc": "Scroll or drag the pill to change the view", "dyn": ["swipe"] },
                    { "kind": "toggle", "label": "Reserve space", "desc": "Tiled windows stop below the pill instead of sliding under it", "dyn": ["reserve"] },
                    { "kind": "select", "label": "Idle view", "desc": "What the compact pill returns to when idle", "dyn": ["idle"], "options": root.dynIdleOptions }
                ] },
                { "name": "Views", "rows": [
                    { "kind": "toggle", "label": "Clock", "desc": "Time and date", "dyn": ["views", "clock"] },
                    { "kind": "toggle", "label": "Workspaces", "desc": "Separate chip on the left; scroll it to switch workspaces", "dyn": ["views", "workspaces"] },
                    { "kind": "toggle", "label": "Music", "desc": "Now playing in the centre; click it or the music button to open the player", "dyn": ["views", "music"] },
                    { "kind": "toggle", "label": "Notifications", "desc": "Latest notification page; arriving notifications expand the pill", "dyn": ["views", "notifications"] }
                ] },
                { "name": "Frame", "rows": [
                    { "kind": "toggle", "label": "Screen frame", "desc": "Border around the screen with rounded inner corners", "dyn": ["frame"] },
                    { "kind": "info", "label": "Frame size and colours", "desc": "The frame thickness, corner rounding and colour mode are shared with the Side bar", "text": "Set under Side (bar 3)" }
                ] },
                { "name": "On-screen display", "rows": [
                    { "kind": "toggle", "label": "Volume and brightness sliders", "desc": "Right-edge sliders: appear when volume or brightness changes, or when you hover the right edge", "osd": "dynamic" }
                ] },
                { "name": "Reset", "rows": [
                    { "kind": "button", "label": "Reset the Dynamic bar", "desc": "Back to the default behaviour and views", "action": "resetDynamic", "value": "Reset" }
                ] },
                { "name": "Island widgets", "rows": [
                    { "kind": "info", "label": "Inside the island", "desc": "", "text": "Wallpaper, screenshot, clipboard, power, launcher, dashboard and GitHub" },
                    { "kind": "info", "label": "Keys", "desc": "", "text": "Super+Shift+D dashboard · Super+Shift+I GitHub · Super+V clipboard · Super+X power" }
                ] }
            ] },

            { "key": "mouse", "title": "Mouse & Touchpad", "icon": "cursor", "section": "INPUT & HARDWARE", "sub": "Speed, acceleration, scrolling and gestures", "component": mouseComp },
            { "key": "keyboard", "title": "Keyboard & Clipboard", "icon": "keyboard", "section": "INPUT & HARDWARE", "sub": "Layouts, repeat delay and clipboard history", "component": inputComp },

            { "key": "apps", "title": "App Appearance", "icon": "font", "section": "SYSTEM", "sub": "GTK, fonts, icons and cursor for this session", "sections": [
                { "name": "GTK theme", "rows": [
                    { "kind": "picker", "label": "GTK theme", "desc": "Empty = adw-gtk3 following light/dark. Only adw-gtk3 takes the shell colours", "app": "gtk_theme", "list": "gtkThemes", "placeholder": "adw-gtk3 (auto)" }
                ] },
                { "name": "Font", "rows": [
                    { "kind": "picker", "label": "App font", "desc": "Font for GTK and Qt apps. The shell font is not affected", "app": "gtk_font", "list": "fonts", "placeholder": "Font family" },
                    { "kind": "stepper", "label": "App font size", "desc": "Point size for GTK and Qt apps", "app": "gtk_font_size", "from": 6, "to": 32, "step": 1, "suffix": " pt" }
                ] },
                { "name": "Icons", "rows": [
                    { "kind": "picker", "label": "Icon theme", "desc": "Icons in GTK and Qt apps", "app": "icon_theme", "list": "iconThemes", "placeholder": "Icon theme" }
                ] },
                { "name": "Cursor", "rows": [
                    { "kind": "picker", "label": "Cursor theme", "desc": "Mouse pointer of this session", "app": "cursor", "list": "cursorThemes", "placeholder": "Cursor theme" },
                    { "kind": "stepper", "label": "Cursor size", "desc": "Pointer size in pixels", "app": "cursor_size", "from": 12, "to": 96, "step": 4, "suffix": " px" }
                ] },
                { "name": "Status", "rows": [
                    { "kind": "info", "label": "Session overlay", "desc": "Apps read these settings through ~/.minflair. If inactive, log out and back in with the Minflair Hyprland session.", "info": "overlay" },
                    { "kind": "info", "label": "Where this applies", "desc": "Written to ~/.minflair only; ~/.config GTK/Qt files and gsettings are never touched.", "text": "This session" }
                ] }
            ] },
            { "key": "integrations", "title": "Integrations & Apps", "icon": "apps", "section": "SYSTEM", "sub": "Default applications, quotes and GitHub", "component": integrationsComp },

            { "key": "shortcuts", "title": "Shortcuts", "icon": "keyboard-filled", "section": "ABOUT", "sub": "Keys and mouse for the shell", "sections": [
                { "name": "Keys", "rows": [
                    { "kind": "info", "label": "Super + Alt + 1 / 2 / 3 / 4", "desc": "", "text": "Convex / Island / Side / Dynamic bar" },
                    { "kind": "info", "label": "Super + S", "desc": "", "text": "Settings" },
                    { "kind": "info", "label": "Super + Ctrl + S", "desc": "", "text": "Settings, bar pages" },
                    { "kind": "info", "label": "Super + K", "desc": "", "text": "Keybinds cheat sheet" },
                    { "kind": "info", "label": "Super + Shift + D", "desc": "", "text": "Dashboard" },
                    { "kind": "info", "label": "Super + Shift + I", "desc": "", "text": "GitHub widget" },
                    { "kind": "info", "label": "Super + Z", "desc": "", "text": "Quick panel: Wi-Fi, brightness, volume" },
                    { "kind": "info", "label": "Super + X", "desc": "", "text": "Power menu (Dynamic bar)" },
                    { "kind": "info", "label": "Super + V", "desc": "", "text": "Clipboard history (opens in the Dynamic island)" },
                    { "kind": "info", "label": "Ctrl + Alt + W", "desc": "", "text": "Wallpaper selector" }
                ] },
                { "name": "Mouse", "rows": [
                    { "kind": "info", "label": "Scroll on the bar", "desc": "", "text": "Volume (first half), brightness (second half)" },
                    { "kind": "info", "label": "Scroll on workspaces", "desc": "", "text": "Switch workspace" },
                    { "kind": "info", "label": "Middle click on volume", "desc": "", "text": "Mute" },
                    { "kind": "info", "label": "Launcher", "desc": "", "text": "> actions, = calculator" }
                ] }
            ] },
            { "key": "about", "title": "About System", "icon": "info", "section": "ABOUT", "sub": "Hardware, kernel and software environment", "component": systemInfoComp }
        ];
    }

    readonly property var navItems: {
        const out = [];
        let last = "";
        for (let i = 0; i < pages.length; i++) {
            const p = pages[i];
            if (p.section && p.section !== last) {
                out.push({ "section": p.section });
                last = p.section;
            }
            out.push({ "index": i, "title": p.title, "icon": p.icon });
        }
        return out;
    }

    readonly property var results: {
        const out = [];
        const seen = {};
        if (q === "")
            return out;
        for (let p = 0; p < pages.length; p++) {
            const page = pages[p];
            if (!page.sections)
                continue;
            for (let s = 0; s < page.sections.length; s++) {
                const sec = page.sections[s];
                for (let r = 0; r < sec.rows.length; r++) {
                    const row = sec.rows[r];
                    const hay = (row.label + " " + (row.desc || "") + " " + sec.name + " " + page.title).toLowerCase();
                    if (hay.indexOf(q) === -1)
                        continue;
                    const key = row.label + "|" + (row.prop || "") + "|" + JSON.stringify(row.cfg || row.dyn || "");
                    if (seen[key])
                        continue;
                    seen[key] = true;
                    out.push(row);
                }
            }
        }
        return out;
    }

    function pageIndex(key) {
        for (let i = 0; i < pages.length; i++) {
            if (pages[i].key === key)
                return i;
        }
        return -1;
    }

    function getValue(row) {
        if (row.app === "cursor")
            return SettingsService.cursorTheme;
        if (row.app === "cursor_size")
            return SettingsService.cursorSize;
        if (row.app)
            return AppearanceService.values[row.app];
        if (row.osd)
            return SettingsService.osdBars[row.osd] !== false;
        if (row.dyn)
            return SettingsService.dynCfg(row.dyn[0], row.dyn[1]);
        if (row.cfg)
            return SettingsService.sideCfg(row.cfg[0], row.cfg[1]);
        if (row.prop)
            return row.list ? SettingsService[row.prop].join(", ") : SettingsService[row.prop];
        if (row.text !== undefined)
            return row.text;
        if (row.action)
            return row.value;
        switch (row.info) {
        case "overlay": return AppearanceService.lastError !== "" ? ("Error: " + AppearanceService.lastError) : (AppearanceService.overlayActive ? "Active" : "Not active in this session");
        case "weather": return WeatherService.loaded ? (WeatherService.city + ", " + WeatherService.temp + WeatherService.unit) : (WeatherService.errorText || "Loading...");
        case "token": return GithubService.tokenMessage !== "" ? GithubService.tokenMessage : (GithubService.hasToken ? "Valid" : "None");
        case "repos": return GithubService.repos.length + (GithubService.hasToken ? " (" + GithubService.privateRepos + " private)" : "");
        case "stars": return GithubService.totalStars;
        case "forks": return GithubService.totalForks;
        case "open": return GithubService.hasToken ? GithubService.openPRs + " / " + GithubService.openIssues : "-";
        case "lang": return GithubService.topLanguage;
        case "rate": return GithubService.rateLimit > 0 ? GithubService.rateRemaining + " / " + GithubService.rateLimit : "-";
        }
        return "";
    }

    function setValue(row, v) {
        if (row.app === "cursor")
            SettingsService.cursorTheme = v;
        else if (row.app === "cursor_size")
            SettingsService.cursorSize = v;
        else if (row.app)
            AppearanceService.set(row.app, v);
        else if (row.osd)
            SettingsService.setOsdBar(row.osd, v);
        else if (row.dyn)
            SettingsService.setDynCfg(row.dyn[0], row.dyn[1], v);
        else if (row.cfg)
            SettingsService.setSideCfg(row.cfg[0], row.cfg[1], v);
        else if (row.prop)
            SettingsService[row.prop] = row.list ? String(v).split(",").map(s => s.trim()).filter(s => s !== "") : v;
    }

    function act(row) {
        if (row.action === "githubRefresh")
            GithubService.fetchData();
        else if (row.action === "randomWall")
            WallpaperManager.shuffle();
        else if (row.action === "resetLogo")
            SettingsService.setSideCfg("logoImage", undefined, "");
        else if (row.action === "browseLogo")
            logoPicker.running = true;
        else if (row.action === "resetSide")
            SettingsService.sideBarConfig = SettingsService.sideBarDefaults;
        else if (row.action === "resetDynamic")
            SettingsService.dynamicBarConfig = SettingsService.dynamicBarDefaults;
        else if (row.action === "gotoPage") {
            const i = pageIndex(row.page);
            if (i !== -1)
                page = i;
        }
    }

    widgetId: "minflair_settings"
    windowTitle: "Minflair Settings"
    contentPadding: 0
    implicitWidth: 1080
    implicitHeight: 700
    Connections {
        function onPendingSettingsPageChanged() {
            if (!root.isOpen || AppState.pendingSettingsPage === "")
                return ;
            const target = root.pageIndex(AppState.pendingSettingsPage);
            if (target !== -1)
                root.page = target;
            AppState.pendingSettingsPage = "";
        }

        target: AppState
    }

    onPageChanged: {
        pageFlick.contentY = 0;
        Qt.callLater(root.revealNav);
    }

    function revealNav() {
        let y = 0;
        for (let i = 0; i < navItems.length; i++) {
            const item = navItems[i];
            const h = item.section ? 30 : 36;
            if (!item.section && item.index === page) {
                const view = navFlick.height;
                const maxY = Math.max(0, navFlick.contentHeight - view);
                if (y < navFlick.contentY || y + h > navFlick.contentY + view)
                    navFlick.contentY = Math.max(0, Math.min(y - view / 2 + h / 2, maxY));

                return;
            }
            y += h + 2;
        }
    }
    onIsOpenChanged: {
        if (!isOpen)
            return;
        const target = pageIndex(AppState.pendingSettingsPage);
        if (target !== -1)
            page = target;
        AppState.pendingSettingsPage = "";
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 0

        ColumnLayout {
            Layout.fillHeight: true
            Layout.preferredWidth: 250
            Layout.minimumWidth: 250
            Layout.maximumWidth: 250
            Layout.margins: 16
            spacing: 12

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 38
                radius: 10
                color: Theme.bgSecondary
                border.width: searchInput.activeFocus ? 1 : 0
                border.color: Theme.accent

                SvgIcon {
                    id: searchIcon

                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "search"
                    iconSize: 14
                    iconColor: searchInput.activeFocus ? Theme.accent : Theme.muted
                    flat: true
                }

                TextInput {
                    id: searchInput

                    anchors.left: searchIcon.right
                    anchors.leftMargin: 8
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.fg
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.bg
                    font.family: Constants.fontFamily
                    font.pixelSize: Math.round(12 * SettingsService.fontScale)
                    clip: true
                    onTextChanged: root.query = text

                    Text {
                        visible: searchInput.text === ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Search settings"
                        color: Theme.muted
                        font: searchInput.font
                    }
                }
            }

            Flickable {
                id: navFlick

                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: width
                contentHeight: navColumn.implicitHeight + 12
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                Column {
                    id: navColumn

                    width: parent.width
                    spacing: 2

                    Repeater {
                        model: root.navItems

                        Item {
                            required property var modelData

                            width: navColumn.width
                            height: modelData.section ? 30 : 36

                            ThemedText {
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 4
                                visible: !!parent.modelData.section
                                text: parent.modelData.section || ""
                                customSize: Constants.sizeXs + 1
                                font.weight: Font.Bold
                                font.letterSpacing: 0.9
                                color: Theme.muted
                            }

                            SidebarNavRow {
                                anchors.fill: parent
                                visible: !parent.modelData.section
                                iconName: parent.modelData.icon || ""
                                labelText: parent.modelData.title || ""
                                isActive: root.page === parent.modelData.index
                                onRowClicked: {
                                    root.page = parent.modelData.index;
                                    searchInput.text = "";
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            color: Theme.border
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            AppHeader {
                title: root.searching ? "Search" : root.currentPage.title
                category: root.searching ? "RESULTS" : root.currentPage.section
                subtitle: root.searching ? (root.results.length + " matching settings") : root.currentPage.sub
                showDivider: true
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Loader {
                    anchors.fill: parent
                    active: !root.searching && root.currentPage.component !== undefined
                    sourceComponent: root.currentPage.component || null
                }

                Flickable {
                    id: pageFlick

                    anchors.fill: parent
                    anchors.leftMargin: 24
                    anchors.rightMargin: 24
                    anchors.topMargin: 16
                    contentWidth: width
                    contentHeight: pageColumn.implicitHeight + 24
                    clip: true
                    visible: !root.searching && root.currentPage.sections !== undefined
                    boundsBehavior: Flickable.StopAtBounds

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                    }

                    Column {
                        id: pageColumn

                        width: parent.width
                        spacing: 8

                        Repeater {
                            model: !root.searching && root.currentPage.sections ? root.currentPage.sections : []

                            Column {
                                id: sectionColumn

                                required property var modelData

                                width: pageColumn.width
                                spacing: 8

                                ThemedText {
                                    topPadding: 8
                                    text: sectionColumn.modelData.name.toUpperCase()
                                    customSize: Constants.sizeXs + 1
                                    font.weight: Font.Bold
                                    font.letterSpacing: 0.9
                                    color: Theme.accent
                                }

                                Repeater {
                                    model: sectionColumn.modelData.rows

                                    CaelRow {
                                        required property var modelData

                                        width: sectionColumn.width
                                        kind: modelData.kind
                                        label: modelData.label
                                        desc: modelData.desc || ""
                                        value: root.getValue(modelData)
                                        options: modelData.list ? AppearanceService[modelData.list] : (modelData.options || [])
                                        from: modelData.from || 0
                                        to: modelData.to || 100
                                        step: modelData.step || 1
                                        suffix: modelData.suffix || ""
                                        password: modelData.password === true
                                        placeholder: modelData.placeholder || ""
                                        onEdited: (v) => root.setValue(modelData, v)
                                        onClicked: root.act(modelData)
                                    }
                                }
                            }
                        }
                    }
                }

                Flickable {
                    anchors.fill: parent
                    anchors.leftMargin: 24
                    anchors.rightMargin: 24
                    anchors.topMargin: 16
                    contentWidth: width
                    contentHeight: searchColumn.implicitHeight + 24
                    clip: true
                    visible: root.searching
                    boundsBehavior: Flickable.StopAtBounds

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                    }

                    Column {
                        id: searchColumn

                        width: parent.width
                        spacing: 8

                        Repeater {
                            model: root.searching ? root.results : []

                            CaelRow {
                                required property var modelData

                                width: searchColumn.width
                                kind: modelData.kind
                                label: modelData.label
                                desc: modelData.desc || ""
                                value: root.getValue(modelData)
                                options: modelData.list ? AppearanceService[modelData.list] : (modelData.options || [])
                                from: modelData.from || 0
                                to: modelData.to || 100
                                step: modelData.step || 1
                                suffix: modelData.suffix || ""
                                password: modelData.password === true
                                placeholder: modelData.placeholder || ""
                                onEdited: (v) => root.setValue(modelData, v)
                                onClicked: root.act(modelData)
                            }
                        }
                    }
                }
            }
        }
    }

    Process {
        id: logoPicker

        command: ["sh", "-c", "zenity --file-selection --title='Dashboard logo' --file-filter='Images | *.png *.svg *.jpg *.jpeg *.webp' 2>/dev/null || kdialog --getopenfilename \"$HOME\" 'image/*' 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim();
                if (p !== "")
                    SettingsService.setSideCfg("logoImage", undefined, p);
            }
        }
    }

    Shortcut {
        sequence: "Ctrl+F"
        enabled: root.isOpen
        onActivated: searchInput.forceActiveFocus()
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.isOpen && root.searching
        onActivated: {
            searchInput.text = "";
            searchInput.focus = false;
        }
    }

    Shortcut {
        sequence: "Ctrl+Tab"
        enabled: root.isOpen
        onActivated: root.page = (root.page + 1) % root.pages.length
    }

    Shortcut {
        sequence: "Ctrl+Shift+Tab"
        enabled: root.isOpen
        onActivated: root.page = (root.page - 1 + root.pages.length) % root.pages.length
    }

    Component {
        id: personalizationComp

        PersonalizationSettings {
            anchors.fill: parent
        }
    }

    Component {
        id: wallpaperComp

        WallpaperSettings {
            anchors.fill: parent
        }
    }

    Component {
        id: effectsComp

        EffectsSettings {
            anchors.fill: parent
        }
    }

    Component {
        id: windowComp

        WindowSettings {
            anchors.fill: parent
        }
    }

    Component {
        id: mouseComp

        MouseSettings {
            anchors.fill: parent
        }
    }

    Component {
        id: inputComp

        InputAndClipboardSettings {
            anchors.fill: parent
        }
    }

    Component {
        id: profileComp

        ProfileSettings {
            anchors.fill: parent
        }
    }

    Component {
        id: integrationsComp

        IntegrationsSettings {
            anchors.fill: parent
        }
    }

    Component {
        id: systemInfoComp

        SystemInfo {
            anchors.fill: parent
        }
    }
}
