import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    required property Context context

    signal exportRequested()

    id: self
    property var replyParts: []
    readonly property bool showReply: self.replyParts.length > 0

    title: self.showReply ? qsTrId('id_start_qr_unlock') : qsTrId('id_qr_pin_unlock')
    leftItem: BackButton {
        onClicked: {
            if (self.showReply)
                self.clearReply()
            else
                self.popPage()
        }
    }
    rightItem: CloseButton {
        onClicked: self.closeClicked()
    }
    function clearReply() {
        self.replyParts = []
        scanner.reset()
    }
    JadeQRController {
        id: qr_controller
        context: self.context
        onHttpRequest: (request) => {
            const dialog = http_request_dialog.createObject(self, { request, context: self.context })
            dialog.open()
        }
        onResultEncoded: (result) => {
            self.replyParts = result.parts
        }
    }
    contentItem: VFlickable {
        alignment: Qt.AlignTop
        spacing: 15
        Label {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            font.pixelSize: 18
            font.weight: 700
            horizontalAlignment: Label.AlignHCenter
            text: self.showReply ? qsTrId('id_start_qr_unlock') : qsTrId('id_qr_pin_unlock')
            wrapMode: Label.WordWrap
        }
        Label {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            font.pixelSize: 12
            font.weight: 400
            horizontalAlignment: Label.AlignHCenter
            opacity: 0.6
            text: self.showReply ? qsTrId('id_select_s_on_jade_and_scan_this').arg(qsTrId('id_scan_qr_on_jade')) : qsTrId('id_if_jade_is_already_set_up')
            wrapMode: Label.WordWrap
        }
        ScannerView {
            id: scanner
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 10
            Layout.minimumWidth: 320
            Layout.minimumHeight: 320
            visible: !self.showReply
            context: self.context
            onBcurScanned: (result) => qr_controller.process(result)
        }
        Rectangle {
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 10
            implicitWidth: 360
            implicitHeight: 360
            radius: 8
            color: '#FFFFFF'
            visible: self.showReply
            Timer {
                interval: 250
                running: self.showReply && self.replyParts.length > 1
                repeat: true
                onTriggered: reply_qrcode.index = (reply_qrcode.index + 1) % self.replyParts.length
            }
            QRCode {
                id: reply_qrcode
                property int index: 0
                anchors.centerIn: parent
                width: 340
                height: 340
                text: self.replyParts.length > 0 ? self.replyParts[reply_qrcode.index] : ''
            }
        }
        VSpacer {
        }
    }
    function continueAirgapFlow() {
        self.popPage()
        self.exportRequested()
    }
    footerItem: PrimaryButton {
        Layout.fillWidth: true
        visible: self.showReply
        text: qsTrId('id_next')
        onClicked: self.continueAirgapFlow()
    }
    Component {
        id: http_request_dialog
        JadeHttpRequestDialog {
        }
    }
}
