import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import qs.modules
import qs.modules.themeing

// Generic dmenu-protocol picker. Apps that shell out to rofi/dmenu pipe a
// newline-separated list of options to stdin and read the chosen line back
// from stdout. qs-dmenu bridges that contract to this window over IPC.
PanelWindow {
    id: root

    visible: States.dmenuOpen || root.closing
    focusable: true
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    anchors {
        top: true
        right: true
        bottom: true
        left: true
    }

    property bool closing: false

    //fades the backdrop and card in/out; the bridge is unblocked as soon as
    //accept()/cancel() write the reply, so the animation is purely cosmetic.
    property real openProgress: 0
    color: Qt.rgba(0, 0, 0, 0.55 * root.openProgress)

    property string workDir: ""
    property string promptText: "Select"
    property var items: []

    NumberAnimation {
        id: openAnim

        target: root
        property: "openProgress"
        to: 1
        duration: 200
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: closeAnim

        target: root
        property: "openProgress"
        to: 0
        duration: 200
        easing.type: Easing.OutCubic
        onRunningChanged: {
            if (!running && root.closing) {
                root.closing = false;
                States.dmenuOpen = false;
            }
        }
    }

    //read the request's option list. a Process is used instead of FileView
    //because FileView caches its text and won't pick up a new path on each
    //invocation of the picker.
    Process {
        id: readProc

        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const text = this.text;
                root.items = String(text || "").split("\n").filter(line => line !== "");
                root.reveal();
            }
        }
    }

    //the bridge blocks on a FIFO until we write a line (pick) or nothing
    //(cancel). Passing the values as argv avoids shell-quoting the option text.
    Process {
        id: replyProc

        running: false
    }

    IpcHandler {
        target: "dmenu-picker"

        function pick(dir: string, prompt: string) {
            if (!dir)
                return;
            //a second request during a close animation just reuses this window
            closeAnim.stop();
            root.closing = false;

            root.workDir = dir;
            root.promptText = prompt || "Select";
            search.text = "";
            list.currentIndex = 0;

            //async read; reveal() opens the window when the options arrive
            readProc.command = ["cat", dir + "/items"];
            readProc.running = true;
        }
    }

    function reveal() {
        if (!States.dmenuOpen)
            States.dmenuOpen = true;
        else
            root.beginOpen();
    }

    function beginOpen() {
        closeAnim.stop();
        root.openProgress = 0;
        openAnim.restart();
        search.forceActiveFocus();
    }

    function accept(line) {
        if (line === undefined || line === null)
            return;
        replyProc.command = ["sh", "-c", "printf '%s\\n' \"$1\" > \"$2\"", "qs-dmenu", String(line), root.workDir + "/reply"];
        replyProc.running = true;
        root.finish();
    }

    function cancel() {
        //opening and closing the FIFO without writing unblocks the bridge
        //with EOF, which the calling app treats as a cancelled menu.
        replyProc.command = ["sh", "-c", ": > \"$1\"", "qs-dmenu", root.workDir + "/reply"];
        replyProc.running = true;
        root.finish();
    }

    function finish() {
        if (root.closing)
            return;
        root.closing = true;
        openAnim.stop();
        closeAnim.restart();
    }

    onVisibleChanged: {
        if (root.visible)
            root.beginOpen();
    }

    Shortcut {
        sequence: "Escape"
        onActivated: root.cancel()
    }

    Rectangle {
        id: card

        anchors.centerIn: parent
        width: Math.min(700, root.width - 80)
        height: Math.min(560, root.height - 80)
        scale: 0.96 + 0.04 * root.openProgress
        opacity: root.openProgress
        color: Theme.bgcolor
        radius: States.panelRounding

        border {
            width: States.borderOn ? States.borderThick : 0
            color: Theme.bordercolor
        }

        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            Text {
                Layout.fillWidth: true
                text: root.promptText
                color: Theme.text1

                font {
                    family: Theme.fontfamily
                    pixelSize: Theme.fontxxl
                    bold: true
                }

                elide: Text.ElideRight
            }

            TextField {
                id: search

                Layout.fillWidth: true
                implicitHeight: 44
                placeholderText: "Type to filter…"
                placeholderTextColor: Theme.textmuted
                color: Theme.text1
                selectByMouse: true
                focus: root.visible

                font {
                    family: Theme.fontfamily
                    pixelSize: Theme.fontlg
                }

                background: Rectangle {
                    color: Theme.rectcolor
                    radius: States.tagRounding

                    border {
                        width: States.borderOn ? 1 : 0
                        color: Theme.bordercolor
                    }
                }

                onTextChanged: list.currentIndex = 0

                Keys.onUpPressed: {
                    if (list.count === 0)
                        return;
                    list.currentIndex = Math.max(list.currentIndex - 1, 0);
                    list.positionViewAtIndex(list.currentIndex, ListView.Contain);
                }
                Keys.onDownPressed: {
                    if (list.count === 0)
                        return;
                    list.currentIndex = Math.min(list.currentIndex + 1, list.count - 1);
                    list.positionViewAtIndex(list.currentIndex, ListView.Contain);
                }
                Keys.onReturnPressed: {
                    if (list.count > 0)
                        root.accept(list.model[list.currentIndex]);
                }
                Keys.onEnterPressed: {
                    if (list.count > 0)
                        root.accept(list.model[list.currentIndex]);
                }
                Keys.onEscapePressed: root.cancel()
            }

            ListView {
                id: list

                Layout.fillWidth: true
                Layout.fillHeight: true
                model: {
                    const q = search.text.trim().toLowerCase();
                    if (q === "")
                        return root.items;
                    return root.items.filter(item => item.toLowerCase().indexOf(q) >= 0);
                }
                spacing: 6
                clip: true
                currentIndex: 0

                onCountChanged: currentIndex = 0

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    width: list.width
                    implicitHeight: optionText.implicitHeight + 20
                    radius: States.tagRounding
                    color: list.currentIndex === index || optionHover.containsMouse ? Theme.recthovercolor : Theme.rectcolor

                    border {
                        width: States.borderOn ? 1 : 0
                        color: list.currentIndex === index ? Theme.textactive : Theme.bordercolor
                    }

                    Text {
                        id: optionText

                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        verticalAlignment: Text.AlignVCenter
                        text: modelData
                        color: Theme.text1
                        elide: Text.ElideRight

                        font {
                            family: Theme.fontfamily
                            pixelSize: Theme.fontmd
                        }
                    }

                    MouseArea {
                        id: optionHover

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (list.currentIndex === index)
                                root.accept(modelData);
                            else
                                list.currentIndex = index;
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: list.count === 0
                text: search.text.trim() !== "" ? "No matches" : "No options provided"
                color: Theme.textmuted
                horizontalAlignment: Text.AlignHCenter

                font {
                    family: Theme.fontfamily
                    pixelSize: Theme.fontlg
                }
            }

            Text {
                Layout.fillWidth: true
                text: "↑/↓ select · Enter choose · Esc cancel"
                color: Theme.textmuted
                horizontalAlignment: Text.AlignHCenter

                font {
                    family: Theme.fontfamily
                    pixelSize: Theme.fontsm
                }
            }
        }
    }
}
