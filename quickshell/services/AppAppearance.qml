pragma Singleton
import Quickshell
import QtQuick

Singleton {
    property var apps: [
        {
            name: "kitty",
            directory: "$HOME/.config/kitty",
            applied: false
        },
        {
            name: "yur",
            directory: "googly eyes"
        }
    ]
}
