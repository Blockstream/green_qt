import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

FilterPopup {
    required property Context context
    required property AddressModel model
    id: self
    OptionButton {
        text: 'Has transactions'
        checked: self.model.filterHasTransactions
        onClicked: {
            self.model.updateFilterHasTransactions(!self.model.filterHasTransactions)
        }
    }
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        Layout.topMargin: 2
        Layout.bottomMargin: 2
        Layout.leftMargin: 8
        Layout.rightMargin: 8
        color: '#FFF'
        radius: 8
        opacity: 0.2
        visible: true
    }

    component OptionButton: AbstractButton {
        checkable: true
        id: button
        leftPadding: 12
        rightPadding: 12
        topPadding: 8
        bottomPadding: 8
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
                font.pixelSize: 16
                font.weight: 600
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
