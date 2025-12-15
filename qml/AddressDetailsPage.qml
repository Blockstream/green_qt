import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    required property Context context
    required property Address address
    id: self
    title: qsTrId('id_address')
    rightItem: RowLayout {
        spacing: 20
        ShareButton {
            url: self.address.url
        }
        CloseButton {
            onClicked: self.closeClicked()
        }
    }
    footerItem: ColumnLayout {
        spacing: 10
        RegularButton {
            Layout.fillWidth: true
            onClicked: self.StackView.view.push(sign_message_drawer, { context: self.context, address: self.address })
            icon.source: 'qrc:/svg2/signature-light.svg'
            text: qsTrId('id_authenticate_address')
            visible: {
                if (self.context.watchonly) return false
                const network = self.address.account.network
                return network.electrum && !network.liquid
            }
        }
    }
    contentItem: VFlickable {
        alignment: Qt.AlignTop
        spacing: 10
        Pane {
            Layout.fillWidth: true
            padding: 20
            background: Rectangle {
                border.color: '#262626'
                border.width: 1
                color: '#181818'
                radius: 5
            }
            contentItem: ColumnLayout {
                id: qrcode_layout
                spacing: 10
                QRCode {
                    Layout.alignment: Qt.AlignHCenter
                    id: qrcode
                    text: self.address.address
                    implicitHeight: 200
                    implicitWidth: 200
                    radius: 4
                }
                AddressLabel {
                    Layout.alignment: Qt.AlignHCenter
                    address: self.address
                }
                CopyAddressButton {
                    Layout.alignment: Qt.AlignCenter
                    content: self.address.address
                    text: qsTrId('id_copy_address')
                }
            }
        }
        FieldTitle {
            text: qsTrId('id_details')
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
                text: localizedLabel(self.address.type)
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
        VSpacer {
        }
    }
    Component {
        id: sign_message_drawer
        SignMessagePage {
            onCloseClicked: self.closeClicked()
        }
    }
}
