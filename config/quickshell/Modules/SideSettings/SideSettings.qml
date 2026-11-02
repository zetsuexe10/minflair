import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Core.Windows
import qs.Modules.Bar.Styles.Side

// Shell settings in the layout of Caelestia's settings app: search and a navigation list on the
// left, the selected page on the right as rounded rows. Everything is driven by `pages` below, so
// search can look through every row.
AppWindow {
    id: root

    property int page: 0
    property string query: ""
    readonly property string q: query.trim().toLowerCase()

    readonly property var positionOptions: [{ "text": "Left", "value": "left" }, { "text": "Right", "value": "right" }, { "text": "Top", "value": "top" }, { "text": "Bottom", "value": "bottom" }]
    readonly property var dashTabOptions: [{ "text": "Dashboard", "value": 0 }, { "text": "Media", "value": 1 }, { "text": "Performance", "value": 2 }, { "text": "Weather", "value": 3 }]
    readonly property var unitOptions: [{ "text": "°C", "value": false }, { "text": "°F", "value": true }]

    readonly property var pages: [
        { "title": "Bar", "icon": "bar", "sub": "Position, entries and scrolling", "sections": [
            { "name": "Position", "rows": [
                { "kind": "select", "label": "Position", "desc": "Which screen edge the bar sits on", "prop": "sideBarPosition", "options": positionOptions },
                { "kind": "stepper", "label": "Workspaces", "desc": "Total number; the bar shows five at a time and follows the active one", "prop": "numberOfWorkspaces", "from": 1, "to": 20, "step": 1 }
            ] },
            { "name": "Entries", "rows": [
                { "kind": "toggle", "label": "Launcher button", "desc": "Opens the launcher", "cfg": ["entries", "logo"] },
                { "kind": "toggle", "label": "Workspaces", "desc": "Workspace switcher", "cfg": ["entries", "workspaces"] },
                { "kind": "toggle", "label": "Active window", "desc": "Title of the focused window", "cfg": ["entries", "activeWindow"] },
                { "kind": "toggle", "label": "Window title text", "desc": "Show the title text on the bar", "prop": "sideBarWindowTitle" },
                { "kind": "toggle", "label": "System tray", "desc": "Tray icons", "cfg": ["entries", "tray"] },
                { "kind": "toggle", "label": "Status icons", "desc": "Network, Bluetooth, volume, brightness, keyboard, notifications", "cfg": ["entries", "statusIcons"] },
                { "kind": "toggle", "label": "Clock", "desc": "Date and time", "cfg": ["entries", "clock"] },
                { "kind": "toggle", "label": "Power button", "desc": "Hover or click opens the power panel", "cfg": ["entries", "power"] }
            ] },
            { "name": "Popouts and scrolling", "rows": [
                { "kind": "toggle", "label": "Hover popouts", "desc": "Open the Wi-Fi, Bluetooth, sound, calendar and notification panels from their icons", "prop": "sideBarPopouts" },
                { "kind": "toggle", "label": "Scroll workspaces", "desc": "Scroll over the workspaces to switch", "cfg": ["scroll", "workspaces"] },
                { "kind": "toggle", "label": "Scroll volume", "desc": "Scroll the first half of the bar", "cfg": ["scroll", "volume"] },
                { "kind": "toggle", "label": "Scroll brightness", "desc": "Scroll the second half of the bar", "cfg": ["scroll", "brightness"] },
                { "kind": "stepper", "label": "Scroll step", "desc": "Percent per notch for volume and brightness", "prop": "sideScrollStep", "from": 1, "to": 20, "step": 1, "suffix": "%" }
            ] }
        ] },
        { "title": "Frame & Style", "icon": "layout-filled", "sub": "The screen frame the panels grow from", "sections": [
            { "name": "Frame", "rows": [
                { "kind": "toggle", "label": "Screen frame", "desc": "A border around the screen with rounded corners", "cfg": ["frame"] },
                { "kind": "stepper", "label": "Border thickness", "desc": "Width of the frame on the edges without the bar", "cfg": ["border"], "from": 4, "to": 24, "step": 1, "suffix": " px" },
                { "kind": "stepper", "label": "Corner rounding", "desc": "Radius of the inner corners and of the panels", "cfg": ["rounding"], "from": 0, "to": 48, "step": 2, "suffix": " px" }
            ] }
        ] },
        { "title": "Panels", "icon": "star", "sub": "Hover triggers, dashboard and feedback", "sections": [
            { "name": "Hover panels", "rows": [
                { "kind": "toggle", "label": "Power panel", "desc": "Hover the right edge or the power button", "cfg": ["hover", "session"] },
                { "kind": "toggle", "label": "Dashboard", "desc": "Hover the top edge, centre", "cfg": ["hover", "dashboard"] },
                { "kind": "toggle", "label": "Launcher", "desc": "Hover the bottom edge, centre", "cfg": ["hover", "launcher"] }
            ] },
            { "name": "Dashboard", "rows": [
                { "kind": "select", "label": "Opens on", "desc": "Tab shown when the dashboard opens", "prop": "sideDashTab", "options": dashTabOptions },
                { "kind": "toggle", "label": "On-screen feedback", "desc": "Indicator on the right edge for volume, brightness and microphone", "prop": "sideOsd" }
            ] },
            { "name": "Weather", "rows": [
                { "kind": "text", "label": "City", "desc": "Leave empty to locate by IP address", "prop": "weatherCity", "placeholder": "Lisbon" },
                { "kind": "select", "label": "Units", "desc": "Temperature and wind speed", "prop": "weatherFahrenheit", "options": unitOptions },
                { "kind": "info", "label": "Status", "desc": "", "info": "weather" }
            ] }
        ] },
        { "title": "GitHub", "icon": "github", "sub": "Account, token and repositories", "sections": [
            { "name": "Account", "rows": [
                { "kind": "text", "label": "Username", "desc": "Shown on the dashboard", "prop": "githubUsername", "placeholder": "octocat" },
                { "kind": "text", "label": "Personal access token", "desc": "Adds private repositories, commits and open PRs", "prop": "githubToken", "placeholder": "ghp_...", "password": true },
                { "kind": "info", "label": "Token", "desc": "", "info": "token" },
                { "kind": "button", "label": "Refresh", "desc": "Fetch again now", "action": "githubRefresh", "value": "Refresh now" }
            ] },
            { "name": "Overview", "rows": [
                { "kind": "info", "label": "Repositories", "desc": "", "info": "repos" },
                { "kind": "info", "label": "Stars", "desc": "", "info": "stars" },
                { "kind": "info", "label": "Forks", "desc": "", "info": "forks" },
                { "kind": "info", "label": "Open PRs / issues", "desc": "Needs a token", "info": "open" },
                { "kind": "info", "label": "Top language", "desc": "", "info": "lang" },
                { "kind": "info", "label": "API requests left", "desc": "", "info": "rate" }
            ] }
        ] },
        { "title": "Shortcuts", "icon": "keyboard-filled", "sub": "Keys and mouse for the shell", "sections": [
            { "name": "Keys", "rows": [
                { "kind": "info", "label": "Super + Alt + 1 / 2 / 3", "desc": "", "text": "Convex / Island / Side bar" },
                { "kind": "info", "label": "Super + S", "desc": "", "text": "Settings" },
                { "kind": "info", "label": "Super + Ctrl + S", "desc": "", "text": "This panel" },
                { "kind": "info", "label": "Super + K", "desc": "", "text": "Keybinds cheat sheet" },
                { "kind": "info", "label": "Ctrl + Alt + C", "desc": "", "text": "Calendar" }
            ] },
            { "name": "Mouse", "rows": [
                { "kind": "info", "label": "Scroll on the bar", "desc": "", "text": "Volume (first half), brightness (second half)" },
                { "kind": "info", "label": "Scroll on workspaces", "desc": "", "text": "Switch workspace" },
                { "kind": "info", "label": "Middle click on volume", "desc": "", "text": "Mute" },
                { "kind": "info", "label": "Launcher", "desc": "", "text": "> actions, = calculator" }
            ] }
        ] }
    ]

    readonly property var results: {
        const out = [];
        if (q === "")
            return out;
        for (let p = 0; p < pages.length; p++)
            for (let s = 0; s < pages[p].sections.length; s++) {
                const sec = pages[p].sections[s];
                for (let r = 0; r < sec.rows.length; r++) {
                    const row = sec.rows[r];
                    const hay = (row.label + " " + (row.desc || "") + " " + sec.name + " " + pages[p].title).toLowerCase();
                    if (hay.indexOf(q) !== -1)
                        out.push(row);
                }
            }
        return out;
    }

    function getValue(row) {
        if (row.cfg)
            return SettingsService.sideCfg(row.cfg[0], row.cfg[1]);
        if (row.prop)
            return SettingsService[row.prop];
        if (row.text !== undefined)
            return row.text;
        if (row.action)
            return row.value;
        switch (row.info) {
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
        if (row.cfg)
            SettingsService.setSideCfg(row.cfg[0], row.cfg[1], v);
        else if (row.prop)
            SettingsService[row.prop] = v;
    }

    function act(row) {
        if (row.action === "githubRefresh")
            GithubService.fetchData();
    }

    widgetId: "minflair_side_settings"
    windowTitle: "Minflair Shell"
    contentPadding: 0
    implicitWidth: 980
    implicitHeight: 660

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 0

        // ---- navigation ----
        ColumnLayout {
            Layout.fillHeight: true
            Layout.preferredWidth: 270
            Layout.minimumWidth: 270
            Layout.maximumWidth: 270
            Layout.margins: 18
            spacing: 14

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 44
                radius: 22
                color: SideState.card
                border.width: searchInput.activeFocus ? 1 : 0
                border.color: SideState.primary

                SvgIcon {
                    id: searchIcon

                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "search"
                    iconSize: Constants.sizeMd
                    iconColor: searchInput.activeFocus ? SideState.primary : SideState.muted
                    flat: true
                }

                TextInput {
                    id: searchInput

                    anchors.left: searchIcon.right
                    anchors.leftMargin: 10
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    color: SideState.fg
                    selectionColor: SideState.primary
                    selectedTextColor: SideState.surface
                    font.family: Constants.fontFamily
                    font.pixelSize: Math.round(13 * SettingsService.fontScale)
                    clip: true
                    onTextChanged: root.query = text

                    Text {
                        visible: searchInput.text === ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Search settings"
                        color: SideState.muted
                        font: searchInput.font
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Rectangle {
                    id: pill

                    width: parent.width
                    height: 48
                    radius: 24
                    color: SideState.selected
                    y: root.page * 54
                    opacity: root.q === "" ? 1 : 0

                    Behavior on y { NumberAnimation { duration: Constants.animSlow; easing.type: Easing.OutExpo } }
                    Behavior on opacity { NumberAnimation { duration: Constants.animFast } }
                }

                Column {
                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: root.pages

                        Item {
                            id: navItem

                            required property var modelData
                            required property int index
                            readonly property bool current: root.page === index && root.q === ""

                            width: parent.width
                            height: 48

                            Rectangle {
                                anchors.fill: parent
                                radius: 24
                                color: SideState.fg
                                opacity: (navHover.hovered && !navItem.current) ? 0.06 : 0

                                Behavior on opacity { NumberAnimation { duration: Constants.animFast } }
                            }

                            SvgIcon {
                                id: navIcon

                                anchors.left: parent.left
                                anchors.leftMargin: 18
                                anchors.verticalCenter: parent.verticalCenter
                                icon: navItem.modelData.icon
                                iconSize: Constants.sizeMd
                                iconColor: navItem.current ? SideState.primary : SideState.muted
                                flat: true
                            }

                            SideText {
                                anchors.left: navIcon.right
                                anchors.leftMargin: 14
                                anchors.verticalCenter: parent.verticalCenter
                                text: navItem.modelData.title
                                customSize: 13
                                font.bold: navItem.current
                                color: navItem.current ? SideState.fg : SideState.muted
                            }

                            HoverHandler {
                                id: navHover

                                cursorShape: Qt.PointingHandCursor
                            }

                            TapHandler {
                                onTapped: {
                                    searchInput.text = "";
                                    root.page = navItem.index;
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
            color: SideState.outline
        }

        // ---- page ----
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 24
            Layout.bottomMargin: 0
            spacing: 4

            SideText {
                text: root.q !== "" ? "Search" : root.pages[root.page].title
                customSize: 24
                font.bold: true
            }

            SideText {
                text: root.q !== "" ? root.results.length + " results" : root.pages[root.page].sub
                color: SideState.muted
            }

            Flickable {
                id: flick

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: 14
                contentWidth: width
                contentHeight: pageCol.implicitHeight + 24
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                // slide the new page in
                property real shift: 0

                Connections {
                    target: root

                    function onPageChanged() {
                        flick.contentY = 0;
                        fade.restart();
                    }
                }

                ParallelAnimation {
                    id: fade

                    NumberAnimation { target: pageCol; property: "opacity"; from: 0; to: 1; duration: Constants.animNormal }
                    NumberAnimation { target: pageCol; property: "y"; from: 18; to: 0; duration: Constants.animSlow; easing.type: Easing.OutExpo }
                }

                Column {
                    id: pageCol

                    width: flick.width
                    spacing: 8

                    // search results
                    Repeater {
                        model: root.q !== "" ? root.results : []

                        CaelRow {
                            required property var modelData

                            width: pageCol.width
                            kind: modelData.kind
                            label: modelData.label
                            desc: modelData.desc || ""
                            value: root.getValue(modelData)
                            options: modelData.options || []
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

                    // sections of the current page
                    Repeater {
                        model: root.q === "" ? root.pages[root.page].sections : []

                        Column {
                            id: sec

                            required property var modelData

                            width: pageCol.width
                            spacing: 8

                            SideText {
                                topPadding: 10
                                text: sec.modelData.name
                                color: SideState.primary
                                customSize: 12
                                font.bold: true
                            }

                            Repeater {
                                model: sec.modelData.rows

                                CaelRow {
                                    required property var modelData

                                    width: sec.width
                                    kind: modelData.kind
                                    label: modelData.label
                                    desc: modelData.desc || ""
                                    value: root.getValue(modelData)
                                    options: modelData.options || []
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
    }

    Shortcut {
        sequence: "Ctrl+F"
        enabled: root.isOpen
        onActivated: searchInput.forceActiveFocus()
    }
}
