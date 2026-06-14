import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    signal doneClicked()

    property var returnPage: null

    function finishUnlock() {
        if (self.returnPage) {
            self.returnPage.StackView.view.pop(self.returnPage)
        } else {
            self.doneClicked()
        }
    }

    JadeQRController {
        id: qr_controller
        onHttpRequest: (request) => {
            const dialog = http_request_dialog.createObject(self, { request, context: null })
            dialog.open()
        }
        onResultEncoded: (result) => self.pushPage(parts_page, result)
    }
    id: self
    footer: null
    padding: 60
    StackView.onActivated: scanner.reset()
    title: qsTrId('id_qr_pin_unlock')
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
            text: qsTrId('id_scan_qr_on_jade')
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
            text: 'On Jade select QR Mode > QR PIN Unlock > Continue > Enter your PIN'
            wrapMode: Label.WordWrap
        }
        ScannerView {
            id: scanner
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: 350
            Layout.preferredHeight: 350
            Layout.minimumWidth: 350
            Layout.minimumHeight: 350
            Layout.topMargin: 10
            visible: self.StackView.status === StackView.Active
            onBcurScanned: (result) => qr_controller.process(result)
        }
        VSpacer {
        }
    }
    Component {
        id: parts_page
        StackViewPage {
            required property var parts
            footer: null
            padding: 60
            id: page
            title: qsTrId('id_scan_qr_code')
            contentItem: VFlickable {
                alignment: Qt.AlignTop
                spacing: 10
                Timer {
                    interval: 250
                    running: page.parts.length > 1
                    repeat: true
                    onTriggered: reply_qrcode.index = (reply_qrcode.index + 1) % page.parts.length
                }
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
                        source: 'qrc:/svg3/jade_qr_unlock_step_2.svg'
                    }
                    Label {
                        Layout.alignment: Qt.AlignCenter
                        Layout.fillWidth: true
                        Layout.preferredWidth: 0
                        font.pixelSize: 12
                        font.weight: 700
                        horizontalAlignment: Label.AlignHCenter
                        text: 'STEP 2'
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
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    Layout.maximumWidth: 420
                    Layout.preferredWidth: 0
                    spacing: 6
                    HSpacer {
                    }
                    Label {
                        Layout.alignment: Qt.AlignVCenter
                        font.pixelSize: 14
                        font.weight: 400
                        opacity: 0.6
                        text: 'Select'
                    }
                    Image {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredHeight: 24
                        Layout.preferredWidth: 26
                        antialiasing: true
                        fillMode: Image.PreserveAspectFit
                        mipmap: true
                        smooth: true
                        source: 'qrc:/svg2/check.svg'
                    }
                    Label {
                        Layout.alignment: Qt.AlignVCenter
                        font.pixelSize: 14
                        font.weight: 400
                        opacity: 0.6
                        text: 'on Jade and scan this QR code'
                    }
                    HSpacer {
                    }
                }
                QRCode {
                    id: reply_qrcode
                    property int index: 0
                    Layout.alignment: Qt.AlignCenter
                    Layout.topMargin: 10
                    implicitWidth: 280
                    implicitHeight: 280
                    text: page.parts.length > 0 ? page.parts[reply_qrcode.index].toUpperCase() : ''
                }
                PrimaryButton {
                    Layout.alignment: Qt.AlignCenter
                    Layout.minimumWidth: 350
                    Layout.topMargin: 10
                    Layout.bottomMargin: 20
                    text: qsTrId('id_done')
                    onClicked: finishUnlock()
                }
            }
        }
    }
    Component {
        id: http_request_dialog
        JadeHttpRequestDialog {
        }
    }
}
