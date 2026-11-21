pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

import qs.modules

// Shared session actions for the control center and Settings. Lock is instant;
// the rest need a second click within five seconds.
Singleton {
    id: root

    property string pending: ""

    readonly property var actions: [
        {
            id: "lock",
            label: "Lock screen",
            icon: "󰌾",
            needsConfirm: false
        },
        {
            id: "suspend",
            label: "Suspend",
            icon: "󰒲",
            needsConfirm: true
        },
        {
            id: "logout",
            label: "Log out",
            icon: "󰗽",
            needsConfirm: true
        },
        {
            id: "reboot",
            label: "Reboot",
            icon: "",
            needsConfirm: true
        },
        {
            id: "shutdown",
            label: "Shut down",
            icon: "󰐥",
            needsConfirm: true
        }
    ]

    function commandFor(id) {
        switch (id) {
        case "lock":
            return [];
        case "suspend":
            return ["systemctl", "suspend"];
        case "logout":
            // logind is the generic path on Arch; killing the compositor is the
            // fallback for sessions where logind is unavailable.
            return ["pkill", "-TERM", "-x", "mango"];
        case "reboot":
            return ["systemctl", "reboot"];
        case "shutdown":
            return ["systemctl", "poweroff"];
        default:
            return [];
        }
    }

    function requestAction(id) {
        const action = root.actions.find(a => a.id === id);
        if (!action)
            return;

        if (!action.needsConfirm) {
            root.runAction(id);
            return;
        }
        if (root.pending === id) {
            root.pending = "";
            root.runAction(id);
        } else {
            root.pending = id;
            confirmTimer.restart();
        }
    }

    function runAction(id) {
        if (id === "lock") {
            States.lockScreen = true;
            return;
        }
        const cmd = root.commandFor(id);
        if (cmd.length === 0)
            return;
        actionProc.command = cmd;
        actionProc.running = true;
    }

    Timer {
        id: confirmTimer

        interval: 5000
        onTriggered: root.pending = ""
    }

    Process {
        id: actionProc

        command: []
        running: false
    }
}
