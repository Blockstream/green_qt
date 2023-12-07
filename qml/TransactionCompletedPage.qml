import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    required property Transaction transaction
    id: self
    rightItem: CloseButton {
    }
    contentItem: ColumnLayout {
        spacing: 10
        VSpacer {
        }
        Image {
            Layout.alignment: Qt.AlignCenter
            source: 'qrc:/png/transaction_completed.png'
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.bottomMargin: 20
            font.pixelSize: 20
            font.weight: 700
            text: 'Transaction completed'
        }
        Repeater {
            model: self.transaction.data.addressees
            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                font.pixelSize: 14
                font.weight: 400
                horizontalAlignment: Label.AlignHCenter
                text: `You have just transfered ${modelData?.satoshi ?? '??'} to ${modelData?.address ?? '??'}`
                wrapMode: Label.Wrap
            }
        }
        PrimaryButton {
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 20
            text: 'View Transaction'
            onClicked: self.StackView.view.replace(null, transaction_details_page, { transaction: self.transaction }, StackView.PushTransition)
        }
        VSpacer {
        }
    }

    Component {
        id: transaction_details_page
        TransactionView {
        }
    }
}
