import Quickshell
import QtQuick

import qs.modules
import qs.modules.themeing

Rectangle {
    visible: States.notchBar ? false : States.buttonsVisible
    implicitHeight: Math.round(States.barHeight * 0.75)
    implicitWidth: Math.round(States.barHeight * 0.75)
    radius: States.itemRounding
    color: clipMouse.containsMouse ? Theme.recthovercolor : (States.flushItems ? Theme.bgcolor : Theme.rectcolor)

    Behavior on color {
        ColorAnimation {
            duration: 150
        }
    }

    border {
        width: States.borderOn ? 1 : 0
        color: Theme.bordercolor
    }

    Text {
        anchors.centerIn: parent
        text: "\uDB80\uDD4D"
        color: Theme.text1

        font {
            family: Theme.fontfamily
            pixelSize: Theme.fontxl
        }
    }

    MouseArea {
        id: clipMouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (States.clipboardOpen) {
                if (States.clipboardCloser)
                    States.clipboardCloser();
                else
                    States.clipboardOpen = false;
            } else {
                States.clipboardOpen = true;
            }
        }
    }
}
