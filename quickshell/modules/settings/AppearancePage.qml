import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules
import qs.modules.themeing

Flickable {
    id: page

    Layout.fillHeight: true
    Layout.fillWidth: true
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    contentWidth: width
    contentHeight: contentCol.implicitHeight + 20

    //refresh wallpaper counts when the appearance page is opened
    onVisibleChanged: if (visible)
        WallpaperState.rescan()

    //shared by the numeric fields
    function intError(t) {
        if (t == null)
            return "";
        if (t.trim() === "")
            return "";
        var v = parseInt(t);
        if (isNaN(v))
            return "Enter a whole number.";
        if (v < 0)
            return "Value can't be negative.";
        return "";
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
            text: "Theme"
            color: Theme.text1
            font {
                family: Theme.fontfamily
                pixelSize: Theme.fontxxl
                bold: true
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 50
            radius: States.tagRounding
            color: Theme.rectcolor
            border {
                width: States.borderOn ? 1 : 0
                color: Theme.bordercolor
            }

            Text {
                anchors.centerIn: parent
                text: ThemeState.themes[ThemeState.themeIndex].name
                color: Theme.text1
                font {
                    family: Theme.fontfamily
                    pixelSize: Theme.fontlg
                    bold: true
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: States.themeOpen = true
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 50
            radius: States.tagRounding
            color: Theme.rectcolor
            border {
                width: States.borderOn ? 1 : 0
                color: Theme.bordercolor
            }

            Text {
                anchors.centerIn: parent
                text: WallpaperState.fileBasename(WallpaperState.currentWallpaper)
                color: Theme.textmuted
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
                font {
                    family: Theme.fontfamily
                    pixelSize: Theme.fontmd
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: States.wallOpen = true
            }
        }

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

                Text {
                    text: "Border: "
                    color: Theme.text1
                    font {
                        family: Theme.fontfamily
                        pixelSize: Theme.fontxxl
                    }
                }
                Text {
                    text: "toggle the screen border on/off"
                    color: Theme.textmuted
                    font {
                        family: Theme.fontfamily
                        pixelSize: Theme.fontxl
                    }
                }
                Item {
                    Layout.fillWidth: true
                }
                ThemeSwitch {
                    checked: States.borderOn
                    onClicked: States.borderOn = checked
                }
            }
        }

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

                Text {
                    text: "Use Wallpaper for app themes: "
                    color: Theme.text1
                    font {
                        family: Theme.fontfamily
                        pixelSize: Theme.fontxxl
                    }
                }
                Text {
                    text: "colors for apps determined by wallpaper, not shell theme"
                    color: Theme.textmuted
                    font {
                        family: Theme.fontfamily
                        pixelSize: Theme.fontxl
                    }
                }
                Item {
                    Layout.fillWidth: true
                }
                ThemeSwitch {
                    checked: States.useWal
                    onClicked: States.useWal = checked
                }
            }
        }
        Rectangle {
            implicitHeight: 70
            Layout.fillWidth: true
            color: Theme.bgcolor
            radius: States.itemRounding
            RowLayout {
                anchors.centerIn: parent
                spacing: 10

                Text {
                    Layout.alignment: Qt.AlignVCenter
                    text: "Border Thickness: "
                    color: Theme.text1
                    font {
                        family: Theme.fontfamily
                        pixelSize: Theme.fontxxl
                    }
                }

                TextField {
                    id: appearanceBorderThickField
                    implicitHeight: 50
                    implicitWidth: 100
                    placeholderText: States.borderThick
                    placeholderTextColor: Theme.textmuted
                    font {
                        family: Theme.fontfamily
                        pixelSize: Theme.fontxl
                    }
                    color: Theme.text1

                    background: Rectangle {
                        anchors.fill: parent
                        color: Theme.rectcolor
                        radius: States.tagRounding
                    }

                    onAccepted: {
                        var val = parseInt(text);
                        if (!isNaN(val) && val >= 0) {
                            States.borderThick = val;
                        }
                    }
                }

                Text {
                    visible: intError(appearanceBorderThickField.text) !== ""
                    text: intError(appearanceBorderThickField.text)
                    color: Theme.alertcolor
                    font {
                        family: Theme.fontfamily
                        pixelSize: Theme.fontsm
                    }
                }
            }
        }

        Text {
            Layout.topMargin: 6
            text: "Fonts"
            color: Theme.text1
            font {
                family: Theme.fontfamily
                pixelSize: Theme.fontlg
                bold: true
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: fontLayout.implicitHeight + 20
            radius: States.itemRounding
            color: Theme.bgcolor
            border {
                width: States.borderOn ? 1 : 0
                color: Theme.bordercolor
            }

            ColumnLayout {
                id: fontLayout

                anchors.fill: parent
                anchors.margins: 10
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "Font Scale"
                            color: Theme.text1
                            font {
                                family: Theme.fontfamily
                                pixelSize: Theme.fontxxl
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: "multiplies every text size in the shell"
                            color: Theme.textmuted
                            wrapMode: Text.WordWrap
                            font {
                                family: Theme.fontfamily
                                pixelSize: Theme.fontsm
                            }
                        }
                    }

                    Text {
                        text: States.fontScale.toFixed(2) + "×"
                        color: Theme.textactive
                        font {
                            family: Theme.fontfamily
                            pixelSize: Theme.fontxl
                        }
                    }
                }

                ValueSlider {
                    Layout.fillWidth: true
                    from: 0.5
                    to: 2.0
                    step: 0.05
                    wheelStep: 0.05
                    value: States.fontScale
                    showMarker: true
                    markerValue: 1.0
                    onMoved: v => States.fontScale = v
                    onCommitted: v => States.fontScale = v
                }
            }
        }

        Text {
            Layout.topMargin: 6
            text: "Rounding"
            color: Theme.text1
            font {
                family: Theme.fontfamily
                pixelSize: Theme.fontlg
                bold: true
            }
        }

        NumberField {
            label: "Panel Rounding"
            description: "corner radius of panels and popups"
            value: States.panelRounding
            minimum: 0
            maximum: 200
            suffix: "px"
            onCommitted: function (v) {
                States.panelRounding = v;
            }
        }

        NumberField {
            label: "Item Rounding"
            description: "corner radius of cards and list items"
            value: States.itemRounding
            minimum: 0
            maximum: 200
            suffix: "px"
            onCommitted: function (v) {
                States.itemRounding = v;
            }
        }

        NumberField {
            label: "Tag Rounding"
            description: "corner radius of tags and small buttons"
            value: States.tagRounding
            minimum: 0
            maximum: 200
            suffix: "px"
            onCommitted: function (v) {
                States.tagRounding = v;
            }
        }

        NumberField {
            label: "Slider Rounding"
            description: "corner radius of sliders and tracks"
            value: States.sliderRounding
            minimum: 0
            maximum: 200
            suffix: "px"
            onCommitted: function (v) {
                States.sliderRounding = v;
            }
        }

        AppAppearancePage {}
    }
}
