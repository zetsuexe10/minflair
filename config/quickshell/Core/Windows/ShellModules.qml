import QtQuick
import qs.Core.Components
import qs.Modules.Clipboard
import qs.Modules.KeybindsCheatSheet
import qs.Modules.Launcher
import qs.Modules.LockScreen
import qs.Modules.Pomodoro
import qs.Modules.Settings
import qs.Modules.ControlPanel
import qs.Modules.SystemMonitor
import qs.Modules.Dashboard
import qs.Modules.WallpaperSelector

Item {
    id: root

    // Bar & media sockets
    WidgetLoader {
        widgetId: "dashboard"
    }

    WidgetLoader {
        widgetId: "controlCenter"
    }

    WidgetLoader {
        widgetId: "notificationsCenter"
    }

    WidgetLoader {
        widgetId: "music"
    }

    WidgetLoader {
        widgetId: "calendar"
    }

    WidgetLoader {
        widgetId: "systemUsage"
    }

    // Application & drawer widgets
    WidgetLoader {
        widgetId: "launcher"

        sourceComponent: Component {
            Launcher {
            }

        }

    }

    WidgetLoader {
        widgetId: "clipboard"

        sourceComponent: Component {
            Clipboard {
            }

        }

    }

    WidgetLoader {
        widgetId: "quickPanel"

        sourceComponent: Component {
            ControlPanelWindow {
            }

        }

    }

    WidgetLoader {
        widgetId: "sysMonitor"

        sourceComponent: Component {
            SystemMonitorWindow {
            }

        }

    }

    WidgetLoader {
        widgetId: "speedTest"

        sourceComponent: Component {
            SpeedTestWindow {
            }

        }

    }

    WidgetLoader {
        widgetId: "github"

        sourceComponent: Component {
            GithubWindow {
            }

        }

    }

    WidgetLoader {
        widgetId: "wallpaper"

        sourceComponent: Component {
            WallpaperSelector {
            }

        }

    }

    WidgetLoader {
        widgetId: "screenshot"
    }

    WidgetLoader {
        widgetId: "powerMenu"
    }

    // Standalone application windows
    WidgetLoader {
        widgetId: "minflair_keybinds"
        exclusive: false

        sourceComponent: Component {
            KeybindsCheatSheet {
            }

        }

    }

    WidgetLoader {
        widgetId: "minflair_settings"
        exclusive: false

        sourceComponent: Component {
            Settings {
            }

        }

    }

    WidgetLoader {
        widgetId: "pomodoro"
        exclusive: false

        sourceComponent: Component {
            Pomodoro {
            }

        }

    }

    LockScreen {
        id: lockScreen
    }

}
