import Blockstream.Green 0.1
import QtMultimedia 5.13
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

ColumnLayout {
    id: send_view
    property alias address: address_field.address
    property alias amount: amount_field.amount
    property alias sendAll: send_all_button.checked

    spacing: 16

    property var _result
    property var methods

    property Action acceptAction: Action {
        text: qsTr('id_send')
        enabled: !!account && !controller.busy && controller.transaction.error === ''
        onTriggered: controller.send()
    }

    property var actions: [acceptAction]

    states: [
        State {
            name: 'SCAN_QR_CODE'
            PropertyChanges {
                target: camera
                cameraState: Camera.ActiveState
            }
        }
    ]

    property Camera camera: Camera {
        cameraState: Camera.LoadedState
        focus {
            focusMode: CameraFocus.FocusContinuous
            focusPointMode: CameraFocus.FocusPointAuto
        }
    }

    transitions: [
        Transition {
            to: 'SCAN_QR_CODE'
            StackViewPushAction {
                stackView: stack_view

                ScannerView {
                    cancelAction.onTriggered: send_view.state = ''
                    source: camera

                    onCodeScanned: {
                        address_field.address = WalletManager.parseUrl(code).address
                        send_view.state = ''
                    }
                }
            }
        },
        Transition {
            from: 'SCAN_QR_CODE'
            ScriptAction {
                script: stack_view.pop()
            }
        }

    ]

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
        text: controller.transaction.error || ''
    }

    AddressField {
        id: address_field
        Layout.fillWidth: true
        label: qsTr("id_recipient")

        onOpenScanner: send_view.state = 'SCAN_QR_CODE'
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
}
