import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Calendar
import qs.Modules.Clipboard
import qs.Modules.ControlCenter
import qs.Modules.Dashboard
import qs.Modules.Launcher
import qs.Modules.Music
import qs.Modules.NotificationCenter
import qs.Modules.PowerMenu
import qs.Modules.ScreenCapture
import qs.Modules.SystemUsage as SystemUsageModule
import qs.Modules.WallpaperSelector

// Hosts every widget (control center, dashboard, calendar, launcher, ...) and the notification
// toasts while the "side" bar style is active. Panels open next to the bar; focus widgets such as
// the launcher open centred. Mapped for the whole session, inert for the other styles.
PanelWindow {
    id: root

    required property var notificationService
    required property int barWidth

    readonly property bool isActive: SettingsService.settingsLoaded && SettingsService.barStyle === "side" && !DisplayProfileService.gameModeActive
    readonly property var centered: ["launcher", "clipboard", "wallpaper", "powerMenu", "screenshot"]
    readonly property var handled: ["dashboard", "controlCenter", "notificationsCenter", "music", "calendar", "systemUsage"].concat(centered)
    readonly property string activeId: (isActive && handled.indexOf(AppState.activeWidget) !== -1) ? AppState.activeWidget : ""
    readonly property bool open: activeId !== ""
    readonly property bool needsFocus: open && centered.indexOf(activeId) !== -1
    property string shownId: ""
    readonly property bool panelVisible: shownId !== ""
    property var _pendingFocusItem: null
    property int _focusAttempts: 0

    function componentFor(id) {
        switch (id) {
        case "dashboard": return dashboardComp;
        case "controlCenter": return controlCenterComp;
        case "notificationsCenter": return notificationsComp;
        case "music": return musicComp;
        case "calendar": return calendarComp;
        case "systemUsage": return systemUsageComp;
        case "launcher": return launcherComp;
        case "clipboard": return clipboardComp;
        case "wallpaper": return wallpaperComp;
        case "powerMenu": return powerMenuComp;
        case "screenshot": return screenshotComp;
        default: return null;
        }
    }

    function prepare(item) {
        if (!item)
            return;
        const resets = ["resetLauncher", "resetClipboard", "resetWallpaperSelector", "resetPowerMenu", "resetScreenCapture"];
        for (let i = 0; i < resets.length; i++)
            if (typeof item[resets[i]] === "function")
                item[resets[i]]();
        if (needsFocus) {
            _pendingFocusItem = item.initialFocusItem ? (item.initialFocusItem.textField ? item.initialFocusItem.textField : item.initialFocusItem) : item;
            _focusAttempts = 0;
            focusTimer.restart();
        }
    }

    onActiveIdChanged: {
        if (activeId !== "") {
            closeTimer.stop();
            shownId = activeId;
        } else {
            closeTimer.restart();
        }
    }

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "minflair-side-overlay"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: needsFocus ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    focusable: needsFocus
    color: "transparent"
    visible: SettingsService.settingsLoaded

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    QtObject {
        id: widgetProxy

        property bool isOpen: root.open
        property int cornerRadius: 24
        property real openProgress: 1
        property real bounceProgress: 1

        function close() {
            AppState.closeAllWidgets();
        }
    }

    Timer {
        id: closeTimer

        interval: Constants.animNormal + 40
        onTriggered: root.shownId = ""
    }

    Timer {
        id: focusTimer

        interval: 30
        repeat: true
        onTriggered: {
            if (!root.needsFocus || !root._pendingFocusItem || root._pendingFocusItem.activeFocus || root._focusAttempts >= 10) {
                stop();
                return;
            }
            root._pendingFocusItem.forceActiveFocus();
            root._focusAttempts++;
        }
    }

    // click outside closes, Escape closes
    MouseArea {
        anchors.fill: parent
        anchors.leftMargin: root.barWidth
        enabled: root.open
        focus: root.needsFocus
        Keys.onEscapePressed: AppState.closeAllWidgets()
        onClicked: AppState.closeAllWidgets()
    }

    Rectangle {
        id: panel

        readonly property bool isCentered: root.centered.indexOf(root.shownId) !== -1
        readonly property bool atTop: root.shownId === "dashboard"
        readonly property int pad: (root.shownId === "powerMenu" || root.shownId === "screenshot") ? 0 : Constants.sizeLg
        readonly property real gap: 4

        visible: opacity > 0.01
        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.96
        transformOrigin: isCentered ? Item.Center : Item.Left
        width: Math.min(content.implicitWidth + pad * 2, root.width - root.barWidth - 24)
        height: Math.min(content.implicitHeight + pad * 2, root.height - 24)
        x: isCentered ? Math.round((root.width - width) / 2) : root.barWidth + gap
        y: isCentered ? Math.round((root.height - height) / 2) : (atTop ? 12 : root.height - height - 12)
        color: Theme.bg
        radius: Constants.size3Xl - 4
        border.width: 1
        border.color: Theme.border

        Behavior on opacity { NumberAnimation { duration: Constants.animNormal; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: Constants.animNormal; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: Constants.animFast; easing.type: Easing.OutCubic } }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        Loader {
            id: content

            anchors.fill: parent
            anchors.margins: panel.pad
            active: root.panelVisible
            sourceComponent: root.componentFor(root.shownId)
            onLoaded: root.prepare(item)
        }
    }

    // notification toast, next to the bar
    Rectangle {
        id: toastBox

        x: root.barWidth + 4
        y: 12
        width: 380
        height: Math.max(toast.notifH, 64)
        radius: 22
        color: Theme.bg
        border.width: 1
        border.color: Theme.border
        opacity: toast.opacity
        visible: toast.visible && root.isActive

        SideNotifLayer {
            id: toast

            property real shownProgress: (hasActiveNotifications && !isRemovingNotif && root.isActive) ? 1 : 0

            anchors.fill: parent
            notificationService: root.notificationService
            notifProgress: shownProgress
            onShownProgressChanged: {
                if (shownProgress === 0 && isRemovingNotif) {
                    isRemovingNotif = false;
                    dismissActiveNotifications();
                }
            }

            Behavior on shownProgress { NumberAnimation { duration: Constants.animNormal; easing.type: Easing.OutCubic } }
        }
    }

    mask: Region {
        Region {
            x: root.barWidth
            y: 0
            width: root.panelVisible ? root.width - root.barWidth : 0
            height: root.panelVisible ? root.height : 0
        }

        Region {
            x: toastBox.x
            y: toastBox.y
            width: toastBox.visible ? toastBox.width : 0
            height: toastBox.visible ? toastBox.height : 0
        }
    }

    Component {
        id: dashboardComp
        DashboardContent { widget: widgetProxy }
    }

    Component {
        id: controlCenterComp
        ControlCenterContent {
            widget: widgetProxy
            notificationService: root.notificationService
        }
    }

    Component {
        id: notificationsComp
        NotificationCenter {
            notificationService: root.notificationService
            controlCenterOpen: true
        }
    }

    Component {
        id: musicComp
        MiniMusicWidget { widget: widgetProxy }
    }

    Component {
        id: calendarComp
        CalendarWidget { widget: widgetProxy }
    }

    Component {
        id: systemUsageComp
        SystemUsageModule.SystemUsageContent { widget: widgetProxy }
    }

    Component {
        id: launcherComp
        LauncherContent { widget: widgetProxy }
    }

    Component {
        id: clipboardComp
        ClipboardContent { widget: widgetProxy }
    }

    Component {
        id: wallpaperComp
        WallpaperSelectorContent { widget: widgetProxy }
    }

    Component {
        id: powerMenuComp
        PowerMenuContent { widget: widgetProxy }
    }

    Component {
        id: screenshotComp
        ScreenCaptureContent { widget: widgetProxy }
    }
}
