pragma Singleton
import Quickshell
import QtQuick
import Quickshell.Services.UPower
import Quickshell.Io

Singleton {
    id: root
    property bool exists: UPower.displayDevice.isLaptopBattery
    property int percentage: Math.round(UPower.displayDevice.percentage * 100)
    property bool isCharging: UPower.displayDevice.state === UPowerDeviceState.Charging

    //edge-triggered so a low-battery notification fires once per discharge,
    //not on every percentage tick below 20
    property bool lowNotified: false
    onPercentageChanged: root.checkLow()
    onExistsChanged: if (root.exists) root.checkLow()
    onIsChargingChanged: {
        if (root.isCharging) {
            root.lowNotified = false;
            chargingProc.running = true;
        } else
            root.checkLow();
    }

    function checkLow() {
        if (root.exists && !root.isCharging && root.percentage < 20 && !root.lowNotified) {
            root.lowNotified = true;
            lowProc.running = true;
        }
    }

    Process {
        id: lowProc

        running: false
        command: ["sh", "-c", "command -v notify-send >/dev/null 2>&1 && notify-send -u critical 'Battery Low' 'Please connect a charger'"]
    }
    Process {
        id: chargingProc

        running: false
        command: ["sh", "-c", "command -v notify-send >/dev/null 2>&1 && notify-send 'Battery is charging' 'Thank you for not killing me'"]
    }
    function get_Battery_Icon() {
        if (root.exists) {
            if (root.isCharging) {
                return "";
            } else if (root.percentage >= 80) {
                return "";
            } else if (root.percentage >= 60) {
                return "";
            } else if (root.percentage >= 40) {
                return "";
            } else if (root.percentage >= 20) {
                return "";
            } else if (root.percentage >= 0) {
                return "";
            } else {
                return "weird battery error";
            }
        } else {
            return "no bat";
        }
    }
    function charge_Icon() {
        if (root.isCharging) {
            return "󱐋";
        } else {
            return "";
        }
    }
}
