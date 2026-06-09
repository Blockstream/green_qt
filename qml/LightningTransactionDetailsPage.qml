import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    required property LightningTransaction transaction

    id: self
    title: qsTrId('id_details')
    rightItem: CloseButton {
        onClicked: self.closeClicked()
    }
    contentItem: VFlickable {
        alignment: Qt.AlignTop
        spacing: 20
        LightningDetail {
            id: preimage_detail
            title: qsTrId('id_payment_preimage')
            value: self.transaction.data.preimage ?? ''
        }
        LineSeparator {
            visible: invoice_detail.visible
        }
        LightningDetail {
            id: invoice_detail
            title: qsTrId('id_invoice')
            value: self.transaction.data.bolt11 ?? ''
        }
        LineSeparator {
            visible: destination_detail.visible
        }
        LightningDetail {
            id: destination_detail
            title: qsTrId('id_destination_public_key')
            value: self.transaction.data.destination ?? ''
        }
        VSpacer {
        }
    }

    component LineSeparator: Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        height: 1
        color: '#404040'
    }

    component LightningDetail: ColumnLayout {
        required property string title
        required property string value

        Layout.fillWidth: true
        id: detail
        spacing: 8
        visible: detail.value !== ''

        Label {
            Layout.fillWidth: true
            color: '#A0A0A0'
            font.pixelSize: 14
            font.weight: 400
            text: detail.title
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 24
            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                color: '#FAFAFA'
                font.pixelSize: 14
                font.weight: 600
                lineHeight: 20
                lineHeightMode: Text.FixedHeight
                text: detail.value
                wrapMode: Label.WrapAnywhere
            }
            DetailCopyButton {
                Layout.alignment: Qt.AlignVCenter
                copyText: detail.value
            }
        }
    }

    component DetailCopyButton: AbstractButton {
        required property string copyText

        id: copy_button
        implicitWidth: 24
        implicitHeight: 24
        opacity: copy_button.hovered ? 1 : 0.6
        contentItem: Image {
            anchors.centerIn: parent
            source: copy_timer.running ? 'qrc:/svg2/check.svg' : 'qrc:/svg2/copy.svg'
        }
        onClicked: {
            Clipboard.copy(copy_button.copyText)
            copy_timer.restart()
        }
        Timer {
            id: copy_timer
            repeat: false
            interval: 1000
        }
    }
}
