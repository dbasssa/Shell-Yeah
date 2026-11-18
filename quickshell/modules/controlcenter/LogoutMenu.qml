import QtQuick
import QtQuick.Layouts
import qs.modules
import qs.modules.themeing
import qs.services

//session actions for the control center; logic lives in SessionActions
ColumnLayout {
    id: root

    Layout.fillWidth: true
    spacing: 6

    Repeater {
        model: SessionActions.actions

        delegate: Rectangle {
            id: actionRow

            required property var modelData

            readonly property bool confirming: SessionActions.pending === actionRow.modelData.id

            Layout.fillWidth: true
            implicitHeight: 30
            radius: States.tagRounding
            color: actionRow.confirming ? Theme.occupiedcolor : (actionMouse.containsMouse ? Theme.recthovercolor : Theme.rectcolor)

            border {
                width: States.borderOn ? 1 : 0
                color: actionRow.confirming ? Theme.alertcolor : Theme.bordercolor
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                Text {
                    text: actionRow.modelData.icon
                    color: actionRow.confirming ? Theme.alertcolor : Theme.text1
                    font {
                        family: Theme.fontfamily
                        pixelSize: Theme.fontbase
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: actionRow.confirming ? "Click again to confirm" : actionRow.modelData.label
                    color: actionRow.confirming ? Theme.alertcolor : Theme.text1
                    elide: Text.ElideRight
                    font {
                        family: Theme.fontfamily
                        pixelSize: Theme.fontbase
                    }
                }
            }

            MouseArea {
                id: actionMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: SessionActions.requestAction(actionRow.modelData.id)
            }
        }
    }

    Text {
        Layout.fillWidth: true
        Layout.topMargin: 2
        text: "Power actions ask for a second click and reset after 5 seconds."
        color: Theme.textmuted
        wrapMode: Text.WordWrap
        font {
            family: Theme.fontfamily
            pixelSize: Theme.fontsm
        }
    }
}
