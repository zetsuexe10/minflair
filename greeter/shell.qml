import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd

// Minflair login screen: runs under greetd inside cage (see tools/install-greeter.sh).
ShellRoot {
    id: shell

    property string pendingPassword: ""
    property var sessionArgv: []

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
            saver.args = [ui.currentUser, ui.currentSession];
            saver.running = true;
            const argv = shell.sessionArgv[ui.sessionIndex];
            console.log("launching session:", JSON.stringify(argv));
            if (!argv) { ui.fail("No session selected"); return; }
            Greetd.launch(argv, [], true);
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
