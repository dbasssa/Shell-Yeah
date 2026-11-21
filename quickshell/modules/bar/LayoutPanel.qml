import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.modules
import qs.modules.themeing
import qs.services

PanelWindow {
    visible: States.layoutSwOpen
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    margins.top: States.frameThickness
    margins.left: States.frameThickness

    color: "transparent"
    MouseArea {
        anchors.fill: parent
        onClicked: States.layoutSwOpen = false
    }

    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        implicitWidth: 200
        implicitHeight: col.implicitHeight + 20
        color: Theme.bgcolor
        radius: States.panelRounding
        border {
            width: States.borderOn ? 1 : 0
            color: Theme.bordercolor
        }

        ColumnLayout {
            id: col
            anchors.centerIn: parent
            Repeater {
                model: Mmsg.layouts
                delegate: Rectangle {
                    implicitWidth: 190
                    implicitHeight: 50
                    Layout.alignment: Qt.AlignHCenter
                    radius: States.itemRounding
                    color: layoutNameClick.containsMouse ? Theme.recthovercolor : Theme.rectcolor
                    MouseArea {
                        id: layoutNameClick
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: {
                            Mmsg.switchLayout(modelData.name);
                            States.layoutSwOpen = false;
                        }
                    }
                    ColumnLayout {
                        anchors.margins: 5
                        anchors.fill: parent
                        Text {
                            color: Theme.text1
                            text: modelData.symbol
                            font {
                                family: Theme.fontfamily
                                pixelSize: Theme.fontlg
                            }
                        }
                        Text {
                            color: Theme.text1
                            text: modelData.name
                            font {
                                family: Theme.fontfamily
                                pixelSize: Theme.fontmd
                            }
                        }
                    }
                }
            }
        }
    }
}
