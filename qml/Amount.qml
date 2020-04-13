import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

Row {
    property alias amount: amount_label.text
    property alias currency: currency_label.text
    property alias pixelSize: amount_label.font.pixelSize

    property bool currencyBorder: true

    padding: 4
    spacing: currencyBorder ? 8 : 4

    Label {
        id: amount_label
        focus: true        
    }

    Label {
        id: currency_label

        font.pixelSize: amount_label.font.pixelSize * 0.75
        visible: currency.length > 0

        anchors.baseline: amount_label.baseline

        Rectangle {
            visible: currencyBorder
            anchors.fill: parent
            anchors.margins: -4
            color: 'transparent'
            border.color: Qt.rgba(1, 1, 1, 0.5)
            border.width: 1
        }
    }
}
