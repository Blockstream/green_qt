import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12
import QtMultimedia 5.13
import QZXing 2.3

ColumnLayout {
    //property var account

    property alias amount: amount_field.amount

    spacing: 16
    property var _account: account

    property var _result
    property var methods

    SendTransactionController {
        id: controller
        address: address_field.address
        amount: parseInt(100000000*amount_field.amount)
        account: _account

        onCodeRequested: {
            methods = result.methods
            methods_dialog.open()
        }

        onEnterResolveCode: swipe_view.currentIndex = 1

        onEnterDone: if (result.action === 'send_raw_tx') {
            _result = result.result
            swipe_view.currentIndex = 2
        }
    }

    Dialog {
        title: swipe_view.currentItem.title
        parent: Overlay.overlay
        anchors.centerIn: Overlay.overlay
        id: methods_dialog
        modal: true
        standardButtons: Dialog.Cancel
        footer: RowLayout {
            PageIndicator {
                count: swipe_view.count
                currentIndex: swipe_view.currentIndex
            }
        }

        Behavior on implicitWidth { enabled: swipe_view.currentIndex !== 0; NumberAnimation { duration: 300 } }
        Behavior on implicitHeight { enabled: swipe_view.currentIndex !== 0; NumberAnimation { duration: 300 } }

        SwipeView {
            anchors.fill: parent

            id: swipe_view
            clip: true
            Column {
                property string title: qsTr('SELECT TWO FACTOR METHOD')
                //anchors.centerIn: parent
                Repeater {
                    model: methods
                    FlatButton {
                        text: modelData
                        onClicked: controller.requestCode(modelData)
                    }
                }
            }

            Column {
                //anchors.centerIn: parent
                property string title: qsTr('ENTER CODE')

                TextField {
                    id: code_field
                }
                FlatButton {
                    text: qsTr('VERIFY')
                    onClicked: controller.resolveCode(code_field.text)
                }
            }

            Column {
                //anchors.centerIn: parent
                property string title: qsTr('SEND')

                Label {
                    text: _result.txhash || '...'
                }
            }
        }

    }

    Pane {
        Layout.fillWidth: true

        ColumnLayout {
            anchors.fill: parent
            AmountConverter {
                id: converter
                wallet: account ? account.wallet : null
                input: ({ btc: amount ? amount : '0' })
            }

            AddressField {
                id: address_field
                Layout.fillWidth: true
                label: qsTr("RECIPIENT")
                address: '2NAXwN5t3Qm3s2ETaAwuYkg4GfQkKGH2J9d'
            }
            FlatButton {
                text: 'QRCODE'
                onClicked: dialog.open()
            }

            RowLayout {
                AmountField {
                    id: amount_field
                    Layout.fillWidth: true
                    currency: 'BTC'
                    label: qsTr('AMOUNT')
                    amount: '0.00001000'
                }

                FlatButton {
                    text: "SEND ALL"
                    onClicked: amount_field.amount = account.json.balance.btc.btc
                }

                Item {
                    Layout.minimumWidth: 16
                }

                AmountField {
                    Layout.fillWidth: true
                    Layout.maximumWidth: 150
                    readOnly: true
                    amount: converter.valid ? converter.output.fiat : ''
                    currency: converter.valid ? converter.output.fiat_currency : ''
                }
            }
        }
    }

    function fee(account, label, duration, blocks) {
        if (!account) return ''
        return qsTr(label) + ' ~ ' + qsTr(duration) + ' (' + Math.round(account.wallet.events.fees[blocks] / 10 + 0.5) / 100 + ' SATOSHI/VBYTE)'
    }

    Pane {
        Layout.fillWidth: true

        ColumnLayout {
            Label {
                text: qsTr('MINER FEE')
            }

            RadioButton {
                checked: true
                text: fee(account, 'FAST', '30 MINUTES', 3)
            }

            RadioButton {
                text: fee(account, 'MEDIUM', '2 HOURS', 12)
            }

            RadioButton {
                text: fee(account, 'SLOW', '4 HOURS', 24)
            }
        }
    }

    FlatButton {
        text: qsTr('SEND')
        enabled: !!account
        onClicked: controller.send()
    }


    Dialog {
        id: dialog
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel

        anchors.centerIn: Overlay.overlay

        property var decoded

        onAccepted: {
            amount_field.amount = decoded.amount
            address_field.address = decoded.address
        }

        header: RowLayout {
            Label {
                text: dialog.decoded ? dialog.decoded.address : '...'
            }

            Label {
                text: dialog.decoded && dialog.decoded.amount.length > 0 ? dialog.decoded.amount : ''
            }
        }

        ColumnLayout {

            VideoOutput {
                Layout.maximumWidth: 400
                Layout.maximumHeight: Layout.maximumWidth / videoOutput.sourceRect.width * videoOutput.sourceRect.height

                id: videoOutput

                autoOrientation: true

                fillMode: VideoOutput.PreserveAspectFit
                source: Camera {
                    cameraState: dialog.visible ? Camera.ActiveState : Camera.UnloadedState
                    focus {
                        focusMode: CameraFocus.FocusContinuous
                        focusPointMode: CameraFocus.FocusPointAuto
                    }
                }

                focus : visible // to receive focus and capture key events when visible

                filters: QZXingFilter {
                    captureRect: {
                        // setup bindings
                        videoOutput.contentRect;
                        videoOutput.sourceRect;
                        return videoOutput.mapRectToSource(videoOutput.mapNormalizedRectToItem(Qt.rect(
                            0, 0, 1, 1
                            //0.25, 0.25, 0.5, 0.5
                        )));
                    }

                    decoder {
                        enabledDecoders: QZXing.DecoderFormat_QR_CODE
                        onTagFound: dialog.decoded = WalletManager.parseUrl(tag)
                    }
                }

                clip: true
                property var size: Math.min(videoOutput.width, videoOutput.height) * 0.8

                Rectangle {
                    visible: false
                    anchors.centerIn: parent
                    color: 'transparent'
                    width: Math.max(videoOutput.width, videoOutput.height)
                    height: Math.max(videoOutput.width, videoOutput.height)
                    border.width: (Math.max(videoOutput.width, videoOutput.height) - videoOutput.size) / 2
                    border.color: Qt.rgba(0, 0, 0, 0.5)
                }
                Rectangle {
                    visible: false
                    anchors.centerIn: parent
                    color: 'transparent'
                    width: videoOutput.size
                    height: videoOutput.size
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.5)
                }
            }
        }
    }
}
