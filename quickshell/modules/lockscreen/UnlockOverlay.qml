import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland

import qs.modules

// Maps before the session unlocks, covering the screen with a frozen copy of
// the lock screen. Once mapped, the session unlocks underneath and a circular
// hole grows from the password field to reveal the live desktop over 600ms.
PanelWindow {
    id: overlay

    required property var controller

    visible: States.unlockRevealOpen
    color: "transparent"
    focusable: false
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay

    anchors {
        top: true
        right: true
        bottom: true
        left: true
    }

    //diameter of the expanding hole
    property real revealSize: 0

    //the window is 0x0 for the first frames after it becomes visible, so never
    //clamp the origin against it — the lock surface already reports valid coords
    readonly property real originX: States.unlockOriginX
    readonly property real originY: States.unlockOriginY
    //big enough to reach the farthest screen corner from the password field
    readonly property real maxSize: 2 * Math.hypot(
        Math.max(originX, overlay.width - originX),
        Math.max(originY, overlay.height - originY)) + 80

    //wait until the compositor has actually sized the window: starting at 0x0
    //would animate an 80px hole in the top-left corner instead of a real reveal
    function beginReveal() {
        if (overlay.width <= 0 || overlay.height <= 0) {
            revealStart.restart();
            return;
        }
        overlay.revealSize = 0;
        overlay.controller.finishUnlock();
        revealAnim.restart();
    }

    Timer {
        id: revealStart
        interval: 16
        onTriggered: overlay.beginReveal()
    }

    //frozen lock appearance. visible:false keeps it off screen; MultiEffect
    //renders it as its source texture.
    LockSurface {
        id: lockCopy

        width: overlay.width
        height: overlay.height
        frozen: true
        controller: overlay.controller
        visible: false
    }

    //white everywhere except the growing hole, which is cleared to transparent.
    //MultiEffect keeps the opaque parts of the lock copy and drops the hole.
    Canvas {
        id: maskCanvas

        width: overlay.width
        height: overlay.height

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.fillStyle = "white";
            ctx.fillRect(0, 0, width, height);
            ctx.globalCompositeOperation = "destination-out";
            ctx.beginPath();
            ctx.arc(overlay.originX, overlay.originY, overlay.revealSize / 2, 0, Math.PI * 2);
            ctx.fill();
            ctx.globalCompositeOperation = "source-over";
        }

        Connections {
            target: overlay

            function onRevealSizeChanged() { maskCanvas.requestPaint() }
            function onWidthChanged() { maskCanvas.requestPaint() }
            function onHeightChanged() { maskCanvas.requestPaint() }
            function onOriginXChanged() { maskCanvas.requestPaint() }
            function onOriginYChanged() { maskCanvas.requestPaint() }
        }
    }

    ShaderEffectSource {
        id: maskTexture

        sourceItem: maskCanvas
        width: overlay.width
        height: overlay.height
        live: true
        hideSource: true
    }

    MultiEffect {
        anchors.fill: parent
        source: lockCopy
        maskEnabled: true
        maskInverted: false
        maskSource: maskTexture
        maskThresholdMin: 0.5
        maskThresholdMax: 1.0
    }

    NumberAnimation {
        id: revealAnim

        target: overlay
        property: "revealSize"
        from: 0
        to: overlay.maxSize
        duration: 600
        easing.type: Easing.OutCubic
        onFinished: States.unlockRevealOpen = false
    }

    onVisibleChanged: if (overlay.visible)
        overlay.beginReveal()
}
