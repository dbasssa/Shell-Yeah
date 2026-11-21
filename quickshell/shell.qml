//@ pragma UseQApplication
import QtQuick
import QtQuick.Layouts
import Quickshell

//Folder imports
import "modules"
import "modules/launcher"
import "modules/bar"
import "modules/controlcenter"
import "modules/settings"
import "modules/lockscreen"
import "modules/themeing"
import "modules/osd"
import "modules/clipboard"
import "modules/dmenu"

ShellRoot {
    Variants {
        model: Quickshell.screens

        Bar {}
    }

    Variants {
        model: Quickshell.screens

        ScreenFrame {}
    }

    Variants {
        model: Quickshell.screens

        Wallpaper {}
    }

    Notifications {}
    AppLauncher {}
    Settings {}
    Lockscreen { id: lockscreenController }
    UnlockOverlay { controller: lockscreenController }
    CtrlCenter{}
    LayoutPanel {}
    ThemeSelector {}
    WallSelector {}
    Clipboard {}
    DmenuPicker {}
    Volosd {}

}
