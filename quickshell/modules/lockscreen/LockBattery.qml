import QtQuick

import qs.modules
import qs.services
import qs.modules.themeing

Row {
    id: root
    spacing: 16
    visible: BluetoothState.connectedDev.length > 0

    Repeater {
        model: BluetoothState.connectedDev

        delegate: Row {
            required property var modelData
            spacing: 6

            Text {
                text: BluetoothState.btDeviceIcon(modelData)
                font.family: Theme.fontfamily
                font.pixelSize: Math.round(22 * States.fontScale)
                color: Theme.text1
            }

            Text {
                visible: modelData.batteryAvailable
                text: BluetoothState.btBatteryIcon(modelData)
                font.family: Theme.fontfamily
                font.pixelSize: Math.round(22 * States.fontScale)
                color: modelData.battery < 0.2 ? Theme.alertcolor : Theme.text1
            }
        }
    }
}
