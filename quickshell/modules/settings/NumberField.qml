import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules
import qs.modules.themeing

// Labelled integer setting shared by the settings pages. The current value is
// shown as the placeholder; typing a number and pressing Enter (or leaving the
// field) commits it. Out-of-range values are clamped.
Rectangle {
    id: row

    property alias label: labelText.text
    property string description: ""
    property int value: 0
    property int minimum: 0
    property int maximum: 100000
    property string suffix: ""
    signal committed(int value)

    Layout.fillWidth: true
    implicitHeight: descText.visible ? 70 : 56
    radius: States.itemRounding
    color: Theme.bgcolor
    border {
        width: States.borderOn ? 1 : 0
        color: Theme.bordercolor
    }

    function commit() {
        if (field.text.trim() === "") {
            field.text = "";
            return;
        }
        const v = parseInt(field.text);
        const clamped = isNaN(v) ? row.value : Math.max(row.minimum, Math.min(row.maximum, v));
        field.text = "";
        row.committed(clamped);
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                id: labelText
                color: Theme.text1
                font {
                    family: Theme.fontfamily
                    pixelSize: Theme.fontxxl
                }
            }
            Text {
                id: descText

                Layout.fillWidth: true
                visible: row.description !== ""
                text: row.description
                color: Theme.textmuted
                wrapMode: Text.WordWrap
                font {
                    family: Theme.fontfamily
                    pixelSize: Theme.fontsm
                }
            }
        }

        TextField {
            id: field

            implicitHeight: 44
            implicitWidth: 90
            horizontalAlignment: Text.AlignHCenter
            placeholderText: String(row.value)
            placeholderTextColor: Theme.textmuted
            validator: IntValidator {
                bottom: row.minimum
                top: row.maximum
            }
            color: Theme.text1
            font {
                family: Theme.fontfamily
                pixelSize: Theme.fontxl
            }
            background: Rectangle {
                color: Theme.rectcolor
                radius: States.tagRounding
            }
            onAccepted: row.commit()
            onEditingFinished: row.commit()
        }

        Text {
            visible: row.suffix !== ""
            text: row.suffix
            color: Theme.textmuted
            font {
                family: Theme.fontfamily
                pixelSize: Theme.fontmd
            }
        }
    }
}
