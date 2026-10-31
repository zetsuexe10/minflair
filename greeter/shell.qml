import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd

// Minflair login screen: runs under greetd inside cage (see tools/install-greeter.sh).
ShellRoot {
    id: shell

    property string pendingPassword: ""
    property var sessionExecs: []

    ListModel { id: users }
    ListModel { id: sessions }

    Process {
        id: lister
        command: ["python3", Quickshell.shellPath("sessions.py")]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    d.users.forEach(u => users.append({ name: u }));
                    shell.sessionExecs = d.sessions.map(s => s.exec);
                    d.sessions.forEach(s => sessions.append({ name: s.name }));
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
            const cmd = shell.sessionExecs[ui.sessionIndex] || "";
            Greetd.launch(["sh", "-c", "exec " + cmd], [], true);
        }
    }

    FloatingWindow {
        visible: true
        color: "#0c0b08"
        Greeter {
            id: ui
            anchors.fill: parent
            userModel: users
            sessionModel: sessions
            onLoginRequested: (user, password, sessionIndex) => {
                shell.pendingPassword = password;
                if (Greetd.state !== GreetdState.Inactive) Greetd.cancelSession();
                Greetd.createSession(user);
            }
            onPowerRequested: action => { power.action = action; power.running = true; }
        }
    }
}
