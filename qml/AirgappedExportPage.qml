import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    required property AirgappedSignController controller
    required property Recipient recipient
    required property Account account
    required property var transaction

    signal importRequested()

    id: self
    title: 'Validate transaction'

    StackView.onActivated: {
        if (self.controller.parts.length === 0 && (self.controller.monitor?.idle ?? true))
            self.controller.exportPsbt()
    }
    rightItem: CloseButton {
        onClicked: self.closeClicked()
    }
    contentItem: VFlickable {
        alignment: Qt.AlignTop
        spacing: 10
        ColumnLayout {
            Layout.alignment: Qt.AlignCenter
            Image {
                Layout.alignment: Qt.AlignCenter
                Layout.preferredHeight: 32
                Layout.preferredWidth: 32
                antialiasing: true
                fillMode: Image.PreserveAspectFit
                mipmap: true
                smooth: true
                source: 'qrc:/svg3/jade_qr_unlock_step_1.svg'
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                font.pixelSize: 12
                font.weight: 700
                horizontalAlignment: Label.AlignHCenter
                text: 'STEP 1'
                wrapMode: Label.WordWrap
            }
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            Layout.topMargin: 10
            font.pixelSize: 26
            font.weight: 600
            horizontalAlignment: Label.AlignHCenter
            text: qsTrId('id_scan_qr_with_jade')
            wrapMode: Label.WordWrap
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            Layout.maximumWidth: 420
            Layout.preferredWidth: 0
            font.pixelSize: 14
            font.weight: 400
            horizontalAlignment: Label.AlignHCenter
            opacity: 0.6
            text: 'On Jade, scan QR and validate transaction details'
            wrapMode: Label.WordWrap
        }
        Rectangle {
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 10
            implicitWidth: 320
            implicitHeight: 320
            radius: 8
            color: '#FFFFFF'
            BusyIndicator {
                anchors.centerIn: parent
                running: self.controller.parts.length === 0
            }
            Timer {
                interval: 250
                running: self.controller.parts.length > 0
                repeat: true
                onTriggered: qrcode.index = (qrcode.index + 1) % self.controller.parts.length
            }
            QRCode {
                id: qrcode
                property int index: 0
                anchors.centerIn: parent
                width: 300
                height: 300
                visible: self.controller.parts.length > 0
                text: self.controller.parts.length > 0 ? self.controller.parts[qrcode.index].toUpperCase() : ''
            }
        }
        FieldTitle {
            Layout.topMargin: 10
            text: qsTrId('id_address')
        }
        AddressLabel {
            Layout.fillWidth: true
            address: self.recipient.address
            background: Rectangle {
                color: '#181818'
                radius: 5
            }
            padding: 20
        }
        FieldTitle {
            text: qsTrId('id_amount')
        }
        AmountField {
            Layout.fillWidth: true
            session: self.account.session
            convert: self.recipient.convert
            readOnly: true
        }
        RowLayout {
            Layout.fillWidth: true
            Convert {
                id: fee_convert
                account: self.account
                input: ({ satoshi: String(self.transaction.fee) })
                unit: self.account.session.unit
            }
            Label {
                Layout.fillWidth: true
                font.pixelSize: 14
                opacity: 0.5
                text: qsTrId('id_network_fee')
            }
            Label {
                font.pixelSize: 14
                text: fee_convert.output.label
            }
        }
        VSpacer {
        }
    }
    Connections {
        target: self.controller
        function onFailed(error) {
            self.pushPage(error_page, { error })
        }
    }
    Component {
        id: error_page
        ErrorPage {
        }
    }
    footerItem: ColumnLayout {
        spacing: 10
        RegularButton {
            Layout.fillWidth: true
            cyan: true
            text: qsTr('Export to file')
            enabled: self.controller.unsignedPsbt.length > 0
            onClicked: self.controller.savePsbtToFile()
        }
        PrimaryButton {
            Layout.fillWidth: true
            text: qsTrId('id_next')
            enabled: self.controller.parts.length > 0
            onClicked: self.importRequested()
        }
    }
}
