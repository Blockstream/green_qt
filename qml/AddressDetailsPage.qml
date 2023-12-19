import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    required property Context context
    required property Address address
    property Action closeAction
    id: self
    title: qsTrId('id_address')
    rightItem: RowLayout {
        spacing: 20
        ShareButton {
            onClicked: Qt.openUrlExternally(self.address.account.network.data.address_explorer_url + self.address.data.address)
        }
        CloseButton {
            action: self.closeAction
            visible: self.closeAction
        }
    }
    footer: ColumnLayout {
        spacing: 10
        RegularButton {
            Layout.fillWidth: true
            onClicked: self.StackView.view.push(sign_message_drawer, { context: self.context, address: self.address })
            icon.source: 'qrc:/svg2/signature-light.svg'
            text: 'Authenticate Address'
            visible: self.address.account.network.electrum && self.address.account.network.mainnet
        }
    }
    contentItem: Flickable {
        ScrollIndicator.vertical: ScrollIndicator {
        }
        id: flickable
        clip: true
        contentWidth: flickable.width
        contentHeight: layout.height
        ColumnLayout {
            id: layout
            spacing: 20
            width: flickable.width
            Pane {
                Layout.fillWidth: true
                padding: 20
                background: Rectangle {
                    radius: 5
                    color: '#222226'
                }
                contentItem: ColumnLayout {
                    id: qrcode_layout
                    spacing: 10
                    QRCode {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillWidth: true
                        Layout.minimumHeight: qrcode_layout.width
                        Layout.preferredWidth: 200
                        id: qrcode
                        text: self.address.data.address
                        implicitHeight: 200
                        implicitWidth: 200
                        radius: 4
                    }
                    Label {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 0
                        font.pixelSize: 12
                        font.weight: 500
                        horizontalAlignment: Label.AlignHCenter
                        text: self.address.data.address
                        wrapMode: Label.WrapAnywhere
                    }
                    CopyAddressButton {
                        Layout.alignment: Qt.AlignCenter
                        content: self.address.data.address
                        text: qsTrId('id_copy_address')
                    }
                }
            }
            RowLayout {
                SectionLabel {
                    Layout.fillWidth: true
                    text: qsTrId('id_address_type')
                }
                Label {
                    Layout.alignment: Qt.AlignRight
                    font.pixelSize: 10
                    font.weight: 700
                    topPadding: 2
                    bottomPadding: 2
                    leftPadding: 6
                    rightPadding: 6
                    text: localizedLabel(self.address.data.address_type)
                    background: Rectangle {
                        radius:  2
                        color: '#68727D'
                    }
                }
            }
            RowLayout {
                SectionLabel {
                    Layout.fillWidth: true
                    text: qsTrId('id_tx_count')
                }
                Label {
                    font.pixelSize: 14
                    font.weight: 600
                    text: self.address.data.tx_count
                }
            }
            Label {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 0
                text: JSON.stringify(self.address.data, null, '  ')
                visible: false
                wrapMode: Label.Wrap
            }
        }
    }
    Component {
        id: sign_message_drawer
        SignMessagePage {
        }
    }
}
