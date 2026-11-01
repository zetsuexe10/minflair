import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Core.Windows
import qs.Modules.Dashboard.Components
import qs.Modules.Settings.Components

// Shell panel with an icon rail on the left and pages that slide in, after Caelestia's settings.
// Covers the Side bar, its dashboard, GitHub and the keyboard shortcuts.
AppWindow {
    id: root

    property int page: 0
    property int previous: 0
    readonly property var pages: [
        { "title": "Side Bar", "subtitle": "Placement, popouts and scrolling", "icon": "bar" },
        { "title": "Dashboard", "subtitle": "Tabs and on-screen feedback", "icon": "layout-filled" },
        { "title": "GitHub", "subtitle": "Account, token and repositories", "icon": "github" },
        { "title": "Shortcuts", "subtitle": "Keys for bars and the shell", "icon": "keyboard-filled" }
    ]

    function go(i) {
        if (i === page)
            return ;
        previous = page;
        page = i;
    }

    widgetId: "minflair_side_settings"
    windowTitle: "Minflair Shell"
    contentPadding: 0
    implicitWidth: 860
    implicitHeight: 600

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 0

        // icon rail
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 76
            color: Theme.bg

            Rectangle {
                anchors.right: parent.right
                width: 1
                height: parent.height
                color: Theme.border
            }

            Rectangle {
                id: marker

                x: (parent.width - width) / 2
                y: 24 + root.page * 64
                width: 52
                height: 52
                radius: 18
                color: Theme.bgAccent

                Behavior on y { NumberAnimation { duration: Constants.animNormal; easing.type: Easing.OutBack; easing.overshoot: 0.9 } }
            }

            Column {
                x: 0
                y: 24
                width: parent.width
                spacing: 12

                Repeater {
                    model: root.pages

                    Item {
                        id: navItem

                        required property var modelData
                        required property int index

                        width: 76
                        height: 52

                        SvgIcon {
                            anchors.centerIn: parent
                            icon: navItem.modelData.icon
                            iconSize: Constants.sizeLg
                            iconColor: root.page === navItem.index ? Theme.accent : (navHover.hovered ? Theme.fg : Theme.muted)
                            flat: true
                        }

                        HoverHandler {
                            id: navHover

                            cursorShape: Qt.PointingHandCursor
                        }

                        TapHandler {
                            onTapped: root.go(navItem.index)
                        }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            AppHeader {
                title: root.pages[root.page].title
                category: "SHELL"
                subtitle: root.pages[root.page].subtitle
                showDivider: true
            }

            Item {
                id: stage

                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                Repeater {
                    model: 4

                    Loader {
                        id: pageLoader

                        required property int index

                        readonly property bool current: root.page === index

                        width: stage.width
                        height: stage.height
                        // only the visited pages are built; the others stay off-screen and unloaded
                        active: current || visited
                        property bool visited: false
                        onCurrentChanged: if (current) visited = true
                        x: current ? 0 : (index < root.page ? -stage.width * 0.2 : stage.width * 0.2)
                        opacity: current ? 1 : 0
                        visible: opacity > 0.01
                        sourceComponent: index === 0 ? sideComp : (index === 1 ? dashComp : (index === 2 ? githubComp : keysComp))

                        Behavior on x { NumberAnimation { duration: Constants.animSlow; easing.type: Easing.OutExpo } }
                        Behavior on opacity { NumberAnimation { duration: Constants.animNormal } }
                    }
                }
            }
        }
    }

    Component {
        id: sideComp

        AppContainer {
            AppGroup {
                title: "Placement"
                icon: "bar"

                SettingSegmented {
                    label: "Position"
                    description: "Which screen edge the bar sits on"
                    model: [{ "text": "Left", "value": "left" }, { "text": "Right", "value": "right" }, { "text": "Top", "value": "top" }, { "text": "Bottom", "value": "bottom" }]
                    currentValue: SettingsService.sideBarPosition
                    onActivated: (value) => SettingsService.sideBarPosition = value
                }

                SettingSpinBox {
                    label: "Number of Workspaces"
                    description: "The bar shows five at a time and follows the active one"
                    value: SettingsService.numberOfWorkspaces
                    from: 1
                    to: 20
                    stepSize: 1
                    decimals: 0
                    suffix: ""
                    onMoved: (val) => SettingsService.numberOfWorkspaces = val
                }

                SettingToggle {
                    label: "Window Title"
                    description: "Show the focused window's title on the bar"
                    checked: SettingsService.sideBarWindowTitle
                    onCheckedChanged: SettingsService.sideBarWindowTitle = checked
                }
            }

            AppGroup {
                title: "Popouts & Scrolling"
                icon: "volume"

                SettingToggle {
                    label: "Hover Popouts"
                    description: "Open the Wi-Fi, Bluetooth and sound panels when hovering their icons"
                    checked: SettingsService.sideBarPopouts
                    onCheckedChanged: SettingsService.sideBarPopouts = checked
                }

                SettingSpinBox {
                    label: "Scroll Step"
                    description: "Percent per notch for brightness and volume. Scroll the first half of the bar for brightness, the second for volume"
                    value: SettingsService.sideScrollStep
                    from: 1
                    to: 20
                    stepSize: 1
                    decimals: 0
                    suffix: "%"
                    onMoved: (val) => SettingsService.sideScrollStep = val
                }
            }
        }
    }

    Component {
        id: dashComp

        AppContainer {
            AppGroup {
                title: "Dashboard"
                icon: "layout-filled"

                SettingSegmented {
                    label: "Opens On"
                    description: "Tab shown when the dashboard opens"
                    model: [{ "text": "Dashboard", "value": 0 }, { "text": "Media", "value": 1 }, { "text": "Performance", "value": 2 }, { "text": "Calendar", "value": 3 }]
                    currentValue: SettingsService.sideDashTab
                    onActivated: (value) => SettingsService.sideDashTab = value
                }

                SettingToggle {
                    label: "On-screen Feedback"
                    description: "Show a pill when volume, brightness or the microphone changes"
                    checked: SettingsService.sideOsd
                    onCheckedChanged: SettingsService.sideOsd = checked
                }
            }
        }
    }

    Component {
        id: githubComp

        AppContainer {
            AppGroup {
                title: "Account"
                icon: "github"

                ThemedText {
                    text: "Username"
                }

                ThemedTextField {
                    Layout.fillWidth: true
                    placeholderText: "octocat"
                    text: SettingsService.githubUsername
                    onEditingFinished: SettingsService.githubUsername = text.trim()
                }

                ThemedText {
                    Layout.topMargin: Constants.sizeSm
                    text: "Personal Access Token"
                }

                ThemedTextField {
                    Layout.fillWidth: true
                    placeholderText: "ghp_xxxxxxxxxxxxxxxxxxxx"
                    isPassword: true
                    text: SettingsService.githubToken
                    onEditingFinished: SettingsService.githubToken = text
                }

                ThemedText {
                    visible: GithubService.tokenMessage !== ""
                    text: GithubService.tokenMessage
                    color: GithubService.tokenStatus === "valid" ? Theme.accent : "#e06b74"
                }

                ThemedText {
                    visible: GithubService.errorMessage !== ""
                    text: GithubService.errorMessage
                    color: "#e06b74"
                }
            }

            AppGroup {
                title: "Overview"
                icon: "star"
                visible: GithubService.username !== ""

                Repeater {
                    model: [
                        { "k": "Repositories", "v": String(GithubService.repos.length) },
                        { "k": "Private", "v": GithubService.hasToken ? String(GithubService.privateRepos) : "needs token" },
                        { "k": "Stars", "v": String(GithubService.totalStars) },
                        { "k": "Forks", "v": String(GithubService.totalForks) },
                        { "k": "Open PRs / Issues", "v": GithubService.hasToken ? GithubService.openPRs + " / " + GithubService.openIssues : "needs token" },
                        { "k": "Top Language", "v": GithubService.topLanguage },
                        { "k": "API Requests Left", "v": GithubService.rateLimit > 0 ? GithubService.rateRemaining + " / " + GithubService.rateLimit : "-" }
                    ]

                    RowLayout {
                        required property var modelData

                        Layout.fillWidth: true

                        ThemedText {
                            Layout.fillWidth: true
                            text: parent.modelData.k
                            color: Theme.muted
                        }

                        ThemedText {
                            text: parent.modelData.v
                            font.bold: true
                        }
                    }
                }

                ThemedButton {
                    text: GithubService.isFetching ? "Refreshing..." : "Refresh Now"
                    enabled: !GithubService.isFetching
                    onClicked: GithubService.fetchData()
                }
            }
        }
    }

    Component {
        id: keysComp

        AppContainer {
            AppGroup {
                title: "Bars"
                icon: "keyboard-filled"

                Repeater {
                    model: [
                        { "k": "Super + Alt + 1 / 2 / 3", "v": "Convex / Island / Side bar" },
                        { "k": "Super + S", "v": "Settings" },
                        { "k": "Super + Ctrl + S", "v": "Shell settings (this panel)" },
                        { "k": "Super + K", "v": "Keybinds cheat sheet" },
                        { "k": "Ctrl + Alt + C", "v": "Calendar" },
                        { "k": "Ctrl + Alt + F", "v": "System usage" },
                        { "k": "Scroll on the bar", "v": "Brightness (first half) / volume (second half)" },
                        { "k": "Scroll on workspaces", "v": "Switch workspace" },
                        { "k": "Middle click volume icon", "v": "Mute" }
                    ]

                    RowLayout {
                        required property var modelData

                        Layout.fillWidth: true

                        ThemedText {
                            Layout.preferredWidth: 220
                            text: parent.modelData.k
                            font.bold: true
                        }

                        ThemedText {
                            Layout.fillWidth: true
                            text: parent.modelData.v
                            color: Theme.muted
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }
    }
}
