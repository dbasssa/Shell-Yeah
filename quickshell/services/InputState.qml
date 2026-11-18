pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

//small input/mode states that don't come from another singleton:
//caps lock comes from the keyboard LEDs; layout and keymode come from the
//shared mmsg watchers in services/Mmsg.qml.
Singleton {
    id: root

    property bool capsLock: false
    property string layout: Mmsg.layout
    property string keymode: Mmsg.keymode

    //"English (US)" -> "US"; leave unnamed layouts untouched
    readonly property string layoutLabel: {
        if (root.layout === "")
            return "";
        const match = root.layout.match(/\(([^)]+)\)/);
        return match ? match[1] : root.layout;
    }

    //there is no portable wayland protocol for lock-key state, so poll the
    //keyboard LEDs (the usual fallback used by wayland bars). exit immediately
    //on machines with no capslock LED instead of looping and printing 0 forever.
    Process {
        command: ["sh", "-c",
            "set -- /sys/class/leds/*::capslock/brightness; [ -r \"$1\" ] || exit 0; "
            + "while :; do v=0; for f in \"$@\"; do [ \"$(cat \"$f\" 2>/dev/null)\" = 1 ] && v=1; done; echo $v; sleep 0.5; done"]
        running: true

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => root.capsLock = String(data).trim() === "1"
        }
    }

}
