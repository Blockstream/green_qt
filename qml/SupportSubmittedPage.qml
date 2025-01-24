import Blockstream.Green.Core
import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    required property string type
    required property var request
    id: self
    title: qsTrId('id_support')
    contentItem: ColumnLayout {
        spacing: 10
        VSpacer {
        }
        CompletedImage {
            Layout.alignment: Qt.AlignCenter
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            font.pixelSize: 26
            font.weight: 600
            text: {
                if (self.type === 'feedback') {
                    return 'Thank you for your feedback'
                } else {
                    return 'Support request created'
                }
            }
        }
        // CopyAddressButton {
        //     Layout.alignment: Qt.AlignCenter
        //     text: `ID ${self.request.id}`
        //     content: self.request.id
        // }
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            Layout.maximumWidth: 300
            horizontalAlignment: Label.AlignHCenter
            text: 'You will receive an email from Blockstream Support'
            visible: self.type !== 'feedback'
            wrapMode: Label.Wrap
        }
        VSpacer {
        }
    }
    footerItem: PrimaryButton {
        text: qsTrId('id_back')
        onClicked: self.StackView.view.pop()
    }
}
