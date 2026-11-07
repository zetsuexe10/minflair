import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd

// Minflair login screen: runs under greetd inside cage (see tools/install-greeter.sh).
ShellRoot {
    id: shell

    property string pendingPassword: ""
    property var sessionArgv: []
    property bool listed: false
    property bool launchQueued: false
    property var queuedArgv: null

    function remember() {
        if (ui.currentUser === "" || ui.currentSession === "")
            return;
        saver.args = [ui.currentUser, ui.currentSession];
        saver.running = false;
        saver.running = true;
    }

    function finishLaunch() {
        if (!shell.launchQueued)
            return;
        shell.launchQueued = false;
        launchTimer.stop();
        console.log("launching session:", JSON.stringify(shell.queuedArgv));
        Greetd.launch(shell.queuedArgv, [], true);
    }

    Process {
        id: lister
        command: ["python3", Quickshell.shellPath("sessions.py")]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    shell.sessionArgv = d.sessions.map(s => s.argv);
                    ui.users = d.users;
                    ui.sessions = d.sessions.map(s => s.name);
                    ui.sessionIndex = d.default;
                    Qt.callLater(() => { shell.listed = true; });
                } catch (e) {
                    console.warn("sessions.py output unreadable:", e);
                }
            }
        }
    }

    Process {
        id: power
        property string action: ""
        command: ["systemctl", action]
    }
    Process {
        id: saver
        property var args: []
        command: ["python3", Quickshell.shellPath("sessions.py"), "--save"].concat(args)
        onExited: shell.finishLaunch()
    }

    Timer {
        id: launchTimer

        interval: 1500
        onTriggered: shell.finishLaunch()
    }

    Connections {
        target: ui
        function onCurrentSessionChanged() {
            if (shell.listed)
                shell.remember();
        }
        function onCurrentUserChanged() {
            if (shell.listed)
                shell.remember();
        }
    }

    Connections {
        target: Greetd
        function onAuthMessage(message, error, responseRequired, echo) {
            if (responseRequired) Greetd.respond(shell.pendingPassword);
        }
        function onAuthFailure(message) {
            shell.pendingPassword = "";
            ui.fail("Wrong password, try again");
        }
        function onReadyToLaunch() {
            shell.pendingPassword = "";
            const argv = shell.sessionArgv[ui.sessionIndex];
            if (!argv) { ui.fail("No session selected"); return; }
            shell.queuedArgv = argv;
            shell.launchQueued = true;
            launchTimer.start();
            shell.remember();
        }
    }

    FloatingWindow {
        visible: true
        color: "#0c0b08"
        Greeter {
            id: ui
            anchors.fill: parent
            onLoginRequested: (user, password, sessionIndex) => {
                shell.pendingPassword = password;
                if (Greetd.state !== GreetdState.Inactive) Greetd.cancelSession();
                Greetd.createSession(user);
            }
            onPowerRequested: action => { power.action = action; power.running = true; }
        }
    }
}
