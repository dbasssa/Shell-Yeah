pragma Singleton
import QtQuick

import qs.services

QtObject {
    id: root

    //persisted settings load from and save to state/state.json through the
    //StateStore service, and each has a control in the Settings window.
    //Properties without StateStore.get() are runtime-only (open/closed flags,
    //registered callbacks, transient layout values, and derived booleans).

    //hydration gate: initial property loads happen before onCompleted, so
    //restored values don't get pointlessly written straight back to disk
    property bool hydrated: false
    Component.onCompleted: root.hydrated = true

    //called from onXChanged handlers to write a property back to state.json
    function persist(key) {
        if (root.hydrated)
            StateStore.set(key, root[key]);
    }

    //osd settings
    property int timerLength: StateStore.get("timerLength", 1000)
    onTimerLengthChanged: root.persist("timerLength")

    //global multiplier applied to every Theme font size
    property real fontScale: StateStore.get("fontScale", 1.0)
    onFontScaleChanged: root.persist("fontScale")
    //brightness level (0-100). runtime-only on purpose: the monitor/backlight
    //owns the real value, this mirrors it. the backend is picked at runtime in
    //services/Deps.qml (brightnessctl for internal panels, ddcutil for DDC/CI).
    property int brightness: 50

    // App launcher open/closed
    property bool appOpen: false
    // Control center open/closed
    property bool ctrlOpen: false
    //Settings App opener
    property bool settingsOpen: false
    //lock screen toggle
    property bool lockScreen: false
    property bool layoutSwOpen: false
    property bool layoutBtnShow: StateStore.get("layoutBtnShow", true)
    onLayoutBtnShowChanged: root.persist("layoutBtnShow")
    //unlock reveal overlay: frozen lock layer with a growing hole (runtime-only)
    property bool unlockRevealOpen: false
    property real unlockOriginX: 0
    property real unlockOriginY: 0
    property bool themeOpen: false
    property bool wallOpen: false
    //clipboard history overlay
    property bool clipboardOpen: false
    //generic dmenu-protocol picker, invoked by external apps through qs-dmenu
    property bool dmenuOpen: false
    //registered by Clipboard so modules can animate its close instead of hard-hiding it
    property var clipboardCloser: null
    //registered by CtrlCenter so modules can animate its close instead of hard-hiding it
    property var ctrlCloser: null
    //registered by CtrlCenter; call when page content grows/shrinks so it resizes to fit
    property var reheight: null
    //extra height pages need on top of their own layout height.
    //set by the audio page (output dropdown) and added by CtrlCenter.
    property int ctrlExtraHeight: 0

    //Bar dimensions when in pill mode (Bound)
    property int barHeight: StateStore.get("barHeight", 30)
    onBarHeightChanged: root.persist("barHeight")
    property int barWidth: StateStore.get("barWidth", 200)
    onBarWidthChanged: root.persist("barWidth")

    //Bar style (Bound): "full" | "island" | "notch"
    property string barStyle: StateStore.get("barStyle", "full")
    onBarStyleChanged: root.persist("barStyle")
    //the style used to be three booleans — kept as derived properties so
    //existing consumers don't have to change
    readonly property bool fullBar: root.barStyle !== "notch"
    readonly property bool islandBar: root.barStyle === "island"
    readonly property bool notchBar: root.barStyle === "notch"
    function fullBarSelect() {
        root.barStyle = "full";
    }
    function islandBarSelect() {
        root.barStyle = "island";
    }
    function notchSelect() {
        root.barStyle = "notch";
    }

    //flatten the bar: drop the outer margin and use the bar background color
    //for every item's card instead of rectcolor. hover color still applies.
    property bool flushItems: StateStore.get("flushItems", false)
    onFlushItemsChanged: root.persist("flushItems")

    //toggles the screen frame along the edges of the monitor (Bound)
    property bool frameVis: StateStore.get("frameVis", false)
    onFrameVisChanged: root.persist("frameVis")
    property int frameThickness: StateStore.get("frameThickness", 5)
    onFrameThicknessChanged: root.persist("frameThickness")
    property int frameRounding: StateStore.get("frameRounding", 0)
    onFrameRoundingChanged: root.persist("frameRounding")

    //outer gap inside bar
    property int barMargin: StateStore.get("barMargin", 12)
    onBarMarginChanged: root.persist("barMargin")
    //gap from top of screen to top of notch
    property int notchMargin: StateStore.get("notchMargin", 5)
    onNotchMarginChanged: root.persist("notchMargin")
    //bar rounding
    property int barRounding: StateStore.get("barRounding", 0)
    onBarRoundingChanged: root.persist("barRounding")

    //general rounding scale
    property int panelRounding: StateStore.get("panelRounding", 20)
    onPanelRoundingChanged: root.persist("panelRounding")
    property int itemRounding: StateStore.get("itemRounding", 20)
    onItemRoundingChanged: root.persist("itemRounding")
    property int tagRounding: StateStore.get("tagRounding", 10)
    onTagRoundingChanged: root.persist("tagRounding")
    property int sliderRounding: StateStore.get("sliderRounding", 5)
    onSliderRoundingChanged: root.persist("sliderRounding")

    //notification card side margin + timeout
    property int notifCardSideMargin: StateStore.get("notifCardSideMargin", 10)
    onNotifCardSideMarginChanged: root.persist("notifCardSideMargin")
    property int notifTimeout: StateStore.get("notifTimeout", 5000)
    onNotifTimeoutChanged: root.persist("notifTimeout")

    //bar module visibility
    property bool wsVisible: StateStore.get("wsVisible", true)
    onWsVisibleChanged: root.persist("wsVisible")
    property bool appsVisible: StateStore.get("appsVisible", true)
    onAppsVisibleChanged: root.persist("appsVisible")
    property bool clockVisible: StateStore.get("clockVisible", true)
    onClockVisibleChanged: root.persist("clockVisible")
    property bool buttonsVisible: StateStore.get("buttonsVisible", true)
    onButtonsVisibleChanged: root.persist("buttonsVisible")
    property bool trayVisible: StateStore.get("trayVisible", true)
    onTrayVisibleChanged: root.persist("trayVisible")
    property bool ctrlCenterVisible: StateStore.get("ctrlCenterVisible", true)
    onCtrlCenterVisibleChanged: root.persist("ctrlCenterVisible")
    property bool indicatorsVisible: StateStore.get("indicatorsVisible", true)
    onIndicatorsVisibleChanged: root.persist("indicatorsVisible")
    property bool themeNameVisible: StateStore.get("themeNameVisible", true)
    onThemeNameVisibleChanged: root.persist("themeNameVisible")

    //borders on control center + popup items
    property bool borderOn: StateStore.get("borderOn", true)
    onBorderOnChanged: root.persist("borderOn")
    property int borderThick: StateStore.get("borderThick", 2)
    onBorderThickChanged: root.persist("borderThick")

    property bool walUse: StateStore.get("walUse", false)
    onWalUseChanged: root.persist("walUse")
}
