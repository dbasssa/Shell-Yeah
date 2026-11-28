import QtQuick
import qs.modules
import qs.modules.themeing
import qs.services

Item {
    id: root
    implicitHeight: parent.implicitHeight - 5
    implicitWidth: batText.implicitWidth
    visible: Battery.exists

    Text {
        id: batText
        anchors.centerIn: parent
        text: Battery.percentage + "% " + Battery.charge_Icon() + Battery.get_Battery_Icon()
        color: Battery.isCharging ? Theme.miconcolor : (Battery.percentage > 20 ? Theme.text1 : Theme.alertcolor)
        font {
            family: Theme.fontfamily
            pixelSize: Theme.fontlg
        }
    }
}
