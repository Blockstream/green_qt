import Blockstream.Green.Core
import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    required property var request
    id: self
    title: qsTrId('id_support')
    contentItem: ColumnLayout {
        spacing: 10
        VSpacer {
        }
        MultiImage {
            Layout.alignment: Qt.AlignCenter
            foreground: 'qrc:/svg2/completed.svg'
            fill: false
            center: true
            width: 300
            height: 182
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            font.pixelSize: 26
            font.weight: 600
            text: 'Support request created'
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
