import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

StackViewPage {
    signal addWallet()
    signal useDevice()
    signal watchOnlyWallet()

    id: self
    footer: null
    padding: 60
    Label {
        Layout.alignment: Qt.AlignCenter
        Layout.maximumWidth: 300
        color: '#FFF'
        font.pixelSize: 30
        font.weight: 656
        horizontalAlignment: Label.AlignHCenter
        text: qsTrId('id_how_do_you_want_to_secure_your')
        wrapMode: Label.WordWrap
    }
    OptionButton {
        Layout.topMargin: 40
        title: qsTrId('id_on_this_device')
        description: 'Your computer will store the keys to your bitcoin, PIN protected.'
        tag: qsTrId('id_for_ease_of_use')
        image: 'qrc:/svg2/funds_sww.svg'
        offsetX: -65
        offsetY: -30
        onClicked: self.addWallet()
    }
    OptionButton {
        Layout.topMargin: 20
        title: 'On Hardware Wallet'
        description: qsTrId('id_your_keys_will_be_secured_on_a')
        tag: 'For Higher Security'
        image: 'qrc:/svg2/funds_hww.svg'
        offsetX: -20
        offsetY: -55
        onClicked: self.useDevice()
    }
    RegularButton {
        Layout.alignment: Qt.AlignCenter
        Layout.minimumWidth: 400
        Layout.topMargin: 40
        text: qsTrId('id_watchonly')
        onClicked: self.watchOnlyWallet()
    }

    component OptionButton: AbstractButton {
        required property string title
        required property string description
        required property string tag
        required property string image
        required property int offsetX
        required property int offsetY
        Layout.alignment: Qt.AlignCenter
        Layout.fillWidth: true
        Layout.maximumWidth: 400
        Layout.preferredHeight: 180
        id: button
        leftPadding: 15
        topPadding: 15
        bottomPadding: 20
        rightPadding: 20
        background: Rectangle {
            color: Qt.lighter('#222226', button.hovered ? 1.2 : 1)
            radius: 4
            Image {
                anchors.right: parent.right
                anchors.rightMargin: button.offsetX
                anchors.top: parent.top
                anchors.topMargin: button.offsetY
                visible: self.enabled
                source: button.image
            }
            Rectangle {
                border.width: 2
                border.color: '#00B45A'
                color: 'transparent'
                radius: 8
                anchors.fill: parent
                anchors.margins: -4
                z: -1
                opacity: button.visualFocus ? 1 : 0
            }
        }
        contentItem: RowLayout {
            ColumnLayout {
                Layout.maximumWidth: 250
                spacing: 10
                Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    color: '#FFF'
                    font.pixelSize: 18
                    font.weight: 600
                    text: button.title
                    wrapMode: Label.WordWrap
                }
                Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    color: '#FFF'
                    font.pixelSize: 12
                    font.weight: 400
                    opacity: 0.6
                    text: button.description
                    wrapMode: Label.WordWrap
                }
                Label {
                    font.pixelSize: 12
                    font.weight: 600
                    padding: 10
                    text: button.tag
                    background: Rectangle {
                        color: '#363636'
                        radius: height / 2
                    }
                }
                VSpacer {
                }
            }
            Image {
                Layout.alignment: Qt.AlignRight | Qt.AlignBottom
                visible: self.enabled
                source: 'qrc:/svg2/next_arrow.svg'
            }
        }
    }
}
