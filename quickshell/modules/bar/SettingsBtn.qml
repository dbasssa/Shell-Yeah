import Quickshell
import QtQuick

import qs.modules
import qs.modules.themeing

Rectangle {
    visible: States.notchBar ? false : States.buttonsVisible
    implicitHeight: Math.round(States.barHeight * 0.75)
    implicitWidth: Math.round(States.barHeight * 0.75)
    radius: States.itemRounding
    color: settMouse.containsMouse ? Theme.recthovercolor : (States.flushItems ? Theme.bgcolor : Theme.rectcolor)
    border {
        width: States.borderOn ? 1 : 0
        color: Theme.bordercolor
    }

    Text {
        id: textId
        anchors.centerIn: parent
        text: ""
        color: Theme.text1
        font {
            pixelSize: Theme.fontxl
        }
    }
    MouseArea {
        id: settMouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: States.settingsOpen = !States.settingsOpen
    }
    Behavior on color {
        ColorAnimation {
            duration: 150
        }
    }
}
