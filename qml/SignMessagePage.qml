import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    required property Context context
    required property Address address
    SignMessageController {
        id: controller
        context: self.context
        address: self.address
        message: text_area.text
        onAccepted: (signature) => self.StackView.view.push(signature_page, { signature })
    }
    TaskPageFactory {
        monitor: controller.monitor
        target: self.StackView.view
    }
    id: self
    title: qsTrId('id_authenticate_address')
    rightItem: CloseButton {
        onClicked: self.closeClicked()
    }
    contentItem: VFlickable {
        alignment: Qt.AlignTop
        spacing: 5
        FieldTitle {
            Layout.topMargin: 0
            text: qsTrId('id_address')
        }
        Pane {
            Layout.fillWidth: true
            background: Rectangle {
                border.color: '#262626'
                border.width: 1
                color: '#181818'
                radius: 5
            }
            contentItem: AddressLabel {
                address: self.address
            }
        }
        FieldTitle {
            text: qsTrId('id_message')
        }
        GTextArea {
            id: text_area
            Layout.fillWidth: true
            Layout.minimumHeight: 160
            enabled: controller.monitor?.idle ?? true
            font.pixelSize: 14
            font.weight: 500
            wrapMode: TextArea.Wrap
            CircleButton {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 20
                activeFocusOnTab: false
                icon.source: 'qrc:/svg2/paste.svg'
                onClicked: {
                    text_area.paste();
                }
            }
        }
        VSpacer {
        }
    }
    footerItem: RowLayout {
        PrimaryButton {
            Layout.fillWidth: true
            enabled: controller.valid && (controller.monitor?.idle ?? true)
            busy: !(controller.monitor?.idle ?? true)
            text: qsTrId('id_sign_message')
            onClicked: controller.sign()
        }
    }

    Component {
        id: signature_page
        SignaturePage {
            onCloseClicked: self.closeClicked()
        }
    }

    component SignaturePage: StackViewPage {
        required property string signature
        id: page
        rightItem: CloseButton {
            onClicked: page.closeClicked()
        }
        contentItem: VFlickable {
            spacing: 20
            CompletedImage {
                Layout.alignment: Qt.AlignHCenter
            }
            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                font.pixelSize: 14
                font.weight: 600
                text: qsTrId('id_this_signature_is_a_proof_of')
                horizontalAlignment: Label.AlignHCenter
                wrapMode: Label.WordWrap
            }
            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                text: page.signature
                font.pixelSize: 12
                font.weight: 500
                horizontalAlignment: Label.AlignHCenter
                wrapMode: Label.Wrap
            }
            CopyAddressButton {
                Layout.alignment: Qt.AlignCenter
                content: page.signature
                text: qsTrId('id_copy_to_clipboard')
            }
        }
    }
}
