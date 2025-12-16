import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

FilterPopup {
    required property Context context
    required property AddressModel model
    id: self
    maximumHeight: Number.POSITIVE_INFINITY
    OptionButton {
        text: 'Has transactions'
        checked: self.model.filterHasTransactions
        onClicked: {
            self.model.updateFilterHasTransactions(!self.model.filterHasTransactions)
        }
    }
    FilterPopup.Separator {
    }
    TypeOptionButton {
        type: 'p2pkh'
    }
    TypeOptionButton {
        type: 'p2sh-p2wpkh'
    }
    TypeOptionButton {
        type: 'p2wpkh'
    }
    TypeOptionButton {
        type: 'p2tr'
    }
    TypeOptionButton {
        type: 'csv'
    }
    TypeOptionButton {
        type: 'p2sh'
    }
    TypeOptionButton {
        type: 'p2wsh'
    }

    component TypeOptionButton: OptionButton {
        required property string type
        id: button
        text: button.type.toUpperCase()
        checked: self.model.filterTypes.indexOf(button.type) >= 0
        onClicked: self.model.updateFilterTypes(button.type, self.model.filterTypes.indexOf(button.type) < 0)
    }

    component OptionButton: AbstractButton {
        Layout.fillWidth: true
        id: button
        checkable: true
        leftPadding: 12
        rightPadding: 12
        topPadding: 4
        bottomPadding: 4
        background: Rectangle {
            color: '#FFF'
            radius: 8
            opacity: 0.2
            visible: button.hovered
        }
        contentItem: RowLayout {
            spacing: 12
            Label {
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true
                font.pixelSize: 14
                font.weight: 400
                text: button.text
                elide: Label.ElideMiddle
            }
            Image {
                Layout.alignment: Qt.AlignCenter
                source: 'qrc:/svg2/check.svg'
                opacity: button.checked ? 1 : 0
            }
        }
    }
}
