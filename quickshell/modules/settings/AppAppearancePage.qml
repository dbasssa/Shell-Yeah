import QtQuick
import QtQuick.Layouts

import qs.modules
import qs.modules.themeing
import qs.services

Rectangle {
    id: root
    Layout.fillWidth: true
    implicitHeight: colLyt.implicitHeight
    color: Theme.rectcolor
    ColumnLayout {
        id: colLyt
        spacing: 5
        Repeater {
            Layout.fillWidth: true
            model: AppAppearance.apps

            delegate: Rectangle {
                color: Theme.recthovercolor
                implicitHeight: 50
                Layout.fillWidth: true
                Layout.margins: 5

                RowLayout {
                    anchors.fill: parent
                    ColumnLayout {
                        spacing: 2
                        Text {
                            color: Theme.text1
                            Layout.leftMargin: 5
                            text: modelData.name
                            font {
                                pixelSize: Theme.fontxxl
                                family: Theme.fontfamily
                            }
                        }

                        Text {
                            color: Theme.textmuted
                            Layout.leftMargin: 5
                            text: modelData.directory
                            font {
                                pixelSize: Theme.fontmd
                                family: Theme.fontfamily
                            }
                        }
                    }
                    Item {
                        Layout.fillWidth: true
                    }

                    ThemeSwitch {
                        checked: modelData.applied
                        onClicked: modelData.applied = checked
                    }
                }
            }
        }
    }
}
