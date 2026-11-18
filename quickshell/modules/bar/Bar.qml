import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.modules
import qs.modules.controlcenter
import qs.modules.themeing

PanelWindow {
    required property var modelData

    screen: modelData
    implicitHeight: States.barHeight
    implicitWidth: States.fullBar ? modelData.width : States.barWidth
    color: "transparent"

    Behavior on implicitHeight {
        NumberAnimation {
            duration: 100
            easing.type: Easing.Linear
        }
    }
    Behavior on implicitWidth {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutInCubic
        }
    }

    anchors {
        top: true
        left: States.fullBar ? true : false
        right: States.fullBar ? true : false
    }

    margins {
        top: States.notchBar ? States.notchMargin : 0
    }

    Rectangle {
        anchors.fill: parent
        color: States.islandBar ? "transparent" : States.notchBar ? Theme.rectcolor : Theme.bgcolor
        radius: States.fullBar ? 0 : States.barRounding
        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }
        Behavior on radius {
            NumberAnimation {
                duration: 150
            }
        }
    }

    RowLayout {
        anchors.leftMargin: States.flushItems ? 0 : States.barMargin
        anchors.rightMargin: States.flushItems ? 0 : States.barMargin
        spacing: 5
        anchors.fill: parent

        Item {
            Layout.fillWidth: true
            visible: States.notchBar ? true : false
        }

        Workspaces {
            monitor: modelData.name
        }

        FocusedApp {}

        //big black clock
        Clock {}

        Item {
            Layout.fillWidth: true
        }

        ClipboardBtn {}
        SettingsBtn {}
        Indicators {}
        SysTray {}
        ThemeName {}

        CtrlCenterBtn {}
    }
}
