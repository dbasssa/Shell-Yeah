import QtQuick
import QtQuick.Layouts
import qs.modules
import qs.modules.themeing
import qs.services

Flickable {
    id: root

    Layout.fillHeight: true
    Layout.fillWidth: true
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    contentWidth: width
    contentHeight: contentCol.implicitHeight + 20

    ColumnLayout {
        id: contentCol

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: 20
        }
        spacing: 10

        Text {
            text: "Power"
            color: Theme.text1
            font {
                family: Theme.fontfamily
                pixelSize: Theme.fontxxl
                bold: true
            }
        }

        //battery (laptops only)
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 70
            visible: Battery.exists
            radius: States.itemRounding
            color: Theme.bgcolor
            border {
                width: States.borderOn ? 1 : 0
                color: Theme.bordercolor
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                Text {
                    text: Battery.get_Battery_Icon()
                    color: Battery.percentage < 20 && !Battery.isCharging ? Theme.alertcolor : Theme.text1
                    font {
                        family: Theme.fontfamily
                        pixelSize: Theme.fontxxl
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "Battery"
                        color: Theme.text1
                        font {
                            family: Theme.fontfamily
                            pixelSize: Theme.fontxxl
                        }
                    }
                    Text {
                        text: Battery.percentage + "% · " + (Battery.isCharging ? "Charging" : "Discharging")
                        color: Theme.textmuted
                        font {
                            family: Theme.fontfamily
                            pixelSize: Theme.fontsm
                        }
                    }
                }
            }
        }

        Text {
            Layout.topMargin: 4
            text: "Session"
            color: Theme.text1
            font {
                family: Theme.fontfamily
                pixelSize: Theme.fontlg
                bold: true
            }
        }

        Repeater {
            model: SessionActions.actions

            delegate: Rectangle {
                id: actionRow

                required property var modelData

                Layout.fillWidth: true
                implicitHeight: 44
                radius: States.tagRounding
                color: SessionActions.pending === actionRow.modelData.id ? Theme.occupiedcolor : (actionMouse.containsMouse ? Theme.recthovercolor : Theme.rectcolor)

                border {
                    width: States.borderOn ? 1 : 0
                    color: SessionActions.pending === actionRow.modelData.id ? Theme.alertcolor : Theme.bordercolor
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    Text {
                        text: actionRow.modelData.icon
                        color: SessionActions.pending === actionRow.modelData.id ? Theme.alertcolor : Theme.text1
                        font {
                            family: Theme.fontfamily
                            pixelSize: Theme.fontxl
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: SessionActions.pending === actionRow.modelData.id ? "Click again to confirm" : actionRow.modelData.label
                        color: SessionActions.pending === actionRow.modelData.id ? Theme.alertcolor : Theme.text1
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
            text: "Destructive actions ask for a second click and reset after 5 seconds."
            color: Theme.textmuted
            wrapMode: Text.WordWrap
            font {
                family: Theme.fontfamily
                pixelSize: Theme.fontsm
            }
        }

    }
}
