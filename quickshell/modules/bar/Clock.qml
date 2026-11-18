import QtQuick
import Quickshell

import qs.modules
import qs.modules.themeing

Rectangle {
    id: root
    visible: States.clockVisible
    clip: true
    property real fontSize: Theme.fontlg
    property string rectColor: Theme.rectcolor

    property bool dateShow: false
    anchors.centerIn: parent
    implicitWidth: clktxt.implicitWidth + 20
    implicitHeight: States.lockScreen ? 50 : Math.round(States.barHeight * 0.75)
    border {
        width: States.borderOn ? 1 : 0
        color: Theme.bordercolor
    }

    color: clockMouse.containsMouse ? Theme.recthovercolor : (States.flushItems ? Theme.bgcolor : Theme.rectcolor)
    radius: States.panelRounding

    SystemClock {
        id: clock

        precision: SystemClock.Seconds
    }
    Text {
        id: clktxt
        anchors.centerIn: parent
        text: root.dateShow ? Qt.formatDateTime(clock.date, "dd MMM yyyy") : Qt.formatDateTime(clock.date, "hh:mm")
        color: Theme.text1
        font {
            family: Theme.fontfamily
            pixelSize: root.fontSize
            bold: true
        }
    }

    MouseArea {
        id: clockMouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.dateShow = !root.dateShow
    }
    Behavior on color {
        ColorAnimation {
            duration: 150
        }
    }
    Behavior on implicitWidth {
        NumberAnimation {
            duration: 150
        }
    }
}
