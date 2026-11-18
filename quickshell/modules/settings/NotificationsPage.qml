import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules
import qs.modules.themeing
import qs.services
import qs.modules.controlcenter

Flickable {
    id: root

    Layout.fillHeight: true
    Layout.fillWidth: true
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    contentWidth: width
    contentHeight: contentCol.implicitHeight + 20

    //accept 0.5s .. 60s, anything else snaps back
    function applyTimeout(field) {
        const v = parseInt(field.text);
        if (isNaN(v)) {
            field.text = String(States.notifTimeout);
            return;
        }
        const clamped = Math.max(500, Math.min(60000, v));
        States.notifTimeout = clamped;
        field.text = String(clamped);
    }

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
            text: "Notifications"
            color: Theme.text1
            font {
                family: Theme.fontfamily
                pixelSize: Theme.fontxxl
                bold: true
            }
        }

        //do not disturb
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 70
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

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "Do Not Disturb"
                        color: Theme.text1
                        font {
                            family: Theme.fontfamily
                            pixelSize: Theme.fontxxl
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: "Hide popups and lock screen cards. Critical notifications still get through."
                        color: Theme.textmuted
                        wrapMode: Text.WordWrap
                        font {
                            family: Theme.fontfamily
                            pixelSize: Theme.fontsm
                        }
                    }
                }

                ThemeSwitch {
                    checked: NotificationState.dnd
                    onClicked: NotificationState.dnd = checked
                }
            }
        }

        //popup timeout
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 70
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

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "Popup timeout"
                        color: Theme.text1
                        font {
                            family: Theme.fontfamily
                            pixelSize: Theme.fontxxl
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: "How long a notification card stays on screen."
                        color: Theme.textmuted
                        wrapMode: Text.WordWrap
                        font {
                            family: Theme.fontfamily
                            pixelSize: Theme.fontsm
                        }
                    }
                }

                TextField {
                    id: timeoutField

                    implicitHeight: 44
                    implicitWidth: 90
                    horizontalAlignment: Text.AlignHCenter
                    text: States.notifTimeout
                    color: Theme.text1
                    validator: IntValidator {
                        bottom: 500
                        top: 60000
                    }
                    font {
                        family: Theme.fontfamily
                        pixelSize: Theme.fontxl
                    }
                    background: Rectangle {
                        color: Theme.rectcolor
                        radius: States.tagRounding
                    }
                    onAccepted: root.applyTimeout(timeoutField)
                    onEditingFinished: root.applyTimeout(timeoutField)
                }

                Text {
                    text: "ms"
                    color: Theme.textmuted
                    font {
                        family: Theme.fontfamily
                        pixelSize: Theme.fontmd
                    }
                }
            }
        }

        NumberField {
            label: "Card Side Margin"
            description: "side spacing of notification cards"
            value: States.notifCardSideMargin
            minimum: 0
            maximum: 100
            suffix: "px"
            onCommitted: function (v) { States.notifCardSideMargin = v }
        }

        //history header
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                Layout.fillWidth: true
                text: "History"
                color: Theme.text1
                font {
                    family: Theme.fontfamily
                    pixelSize: Theme.fontlg
                    bold: true
                }
            }

            Rectangle {
                implicitHeight: 30
                implicitWidth: 80
                radius: States.tagRounding
                color: clearMouse.containsMouse && NotificationState.history.length > 0 ? Theme.recthovercolor : Theme.rectcolor
                border {
                    width: States.borderOn ? 1 : 0
                    color: Theme.bordercolor
                }

                Text {
                    anchors.centerIn: parent
                    text: "Clear all"
                    color: NotificationState.history.length > 0 ? Theme.text1 : Theme.textmuted
                    font {
                        family: Theme.fontfamily
                        pixelSize: Theme.fontmd
                    }
                }

                MouseArea {
                    id: clearMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: NotificationState.history.length > 0
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NotificationState.clearHistory()
                }
            }
        }

        //history list
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 360
            color: "transparent"

            ListView {
                id: list

                anchors.fill: parent
                spacing: 8
                clip: true
                model: NotificationState.history

                delegate: NotificationCard {
                    required property var modelData

                    width: list.width
                    notification: modelData.view
                    timeLabel: modelData.time
                    hoverHighlight: true

                    onBodyClicked: NotificationState.dismissEntry(modelData)
                    onActionClicked: (action) => NotificationState.invokeHistoryAction(modelData, action)
                }
            }

            Text {
                anchors.centerIn: parent
                visible: NotificationState.history.length === 0
                text: "No notifications yet"
                color: Theme.textmuted
                font {
                    family: Theme.fontfamily
                    pixelSize: Theme.fontlg
                }
            }
        }
    }
}
