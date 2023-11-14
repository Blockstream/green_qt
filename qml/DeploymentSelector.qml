import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Pane {
    property string deployment: 'mainnet'
    Layout.alignment: Qt.AlignCenter
    id: self
    padding: 0
    background: Rectangle {
        border.width: 0.5
        border.color: '#313131'
        color: '#121414'
        radius: 4
    }
    contentItem: RowLayout {
        spacing: 0
        Option {
            deployment: 'mainnet'
            text: 'Mainnet'
        }
        Option {
            deployment: 'testnet'
            text: 'Testnet'
        }
    }

    component Option: AbstractButton {
        required property string deployment
        id: option
        checked: self.deployment === option.deployment
        implicitHeight: 35
        implicitWidth: 163
        background: Item {
            Rectangle {
                anchors.fill: parent
                visible: option.checked
                border.width: option.checked ? 1 : 0.5
                border.color: Qt.alpha('#FFF', 0.3)
                color: '#3A3A3D'
                radius: 4
            }
            Rectangle {
                anchors.fill: parent
                anchors.margins: -4
                border.width: 2
                border.color: '#00B45A'
                color: 'transparent'
                radius: 8
                visible: option.visualFocus
            }
        }
        contentItem: Label {
            font.family: 'SF Compact Display'
            font.pixelSize: 12
            font.weight: 600
            horizontalAlignment: Label.AlignHCenter
            verticalAlignment: Label.AlignVCenter
            opacity: option.checked ? 1 : 0.3
            text: option.text
        }
        onClicked: {
            self.deployment = option.deployment
            option.forceActiveFocus(Qt.MouseFocusReason)
        }
    }
}
