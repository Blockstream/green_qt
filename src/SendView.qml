import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12
import QtMultimedia 5.13
import QZXing 2.3

ColumnLayout {
    property alias amount: amount_field.amount
    property var size: controller.transaction.transaction_vsize

    spacing: 16
    property var _account: account

    property var _result
    property var methods

    SendTransactionController {
        id: controller
        address: address_field.address
        amount: amount_field.amount
        account: _account ? _account : null
        sendAll: send_all_button.checked

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
                property string title: qsTr('id_choose_twofactor_authentication')
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
                property string title: qsTr('id_please_provide_your_1s_code').arg("email") // TODO: use methods

                TextField {
                    id: code_field
                }
                FlatButton {
                    text: qsTr('id_next')
                    onClicked: controller.resolveCode(code_field.text)
                }
            }

            Column {
                property string title: qsTr('id_send')

                Label {
                    text: _result ? _result.txhash : '...'
                }
            }
        }

    }

    Label {
        text: controller.transaction.error
    }

    AddressField {
        id: address_field
        Layout.fillWidth: true
        label: qsTr("id_recipient")
    }

    AmountField {
        id: amount_field
        Layout.fillWidth: true
        currency: 'BTC'
        label: qsTr('id_amount')
        enabled: !send_all_button.checked

        Binding on amount {
            when: send_all_button.checked
            value: account.balance
        }
    }

    FlatButton {        
        id: send_all_button
        checkable: true
        text: qsTr('id_send_all_funds')
    }

    Label {
        text: qsTr('id_network_fee')
    }

    FeeComboBox {
        Layout.fillWidth: true
        property var indexes: [3, 12, 24]

        Component.onCompleted: {
            currentIndex = indexes.indexOf(account.wallet.settings.required_num_blocks)
            controller.feeRate = account.wallet.events.fees[blocks]
        }

        onBlocksChanged: {
            console.log('blocks: ', blocks)
            controller.feeRate = account.wallet.events.fees[blocks]
        }
    }

    FlatButton {
        text: qsTr('id_send')
        enabled: !!account && !controller.busy && controller.transaction.error === ''
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
