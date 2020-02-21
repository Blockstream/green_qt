import Blockstream.Green 0.1
import QtMultimedia 5.13
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12
import './views'

StackView {
    id: stack_view
    property alias address: address_field.address
    property Asset asset: asset_field_loader.item.asset
    property alias amount: amount_field.amount
    property alias sendAll: send_all_button.checked

    property var actions: currentItem.actions

    property Item scanner_view: ScannerView {
        source: camera
        onCancel: {
            stack_view.pop();
            camera.stop();
        }
        onCodeScanned: {
            camera.stop();
            address_field.address = WalletManager.parseUrl(code).address;
            stack_view.pop();
        }
    }

    property Camera camera: Camera {
        cameraState: Camera.LoadedState
        focus {
            focusMode: CameraFocus.FocusContinuous
            focusPointMode: CameraFocus.FocusPointAuto
        }
    }

    initialItem: ColumnLayout {

        property list<Action> actions: [Action{
               text: qsTr('id_send')
               enabled: controller.valid && !controller.transaction.error
               onTriggered: controller.send()
           }]

        spacing: 8

        Label {
            text: qsTr(controller.transaction.error) || ''
            color: 'red'
        }

        Loader {
            id: asset_field_loader
            active: wallet.network.liquid
            Layout.fillWidth: true
            sourceComponent: ComboBox {
                property Balance balance: account.balances[asset_field.currentIndex]
                property Asset asset: balance.asset
                id: asset_field
                flat: true
                model: account.balances
                delegate: AssetDelegate {
                    highlighted: index === asset_field.currentIndex
                    balance: modelData
                    showIndicator: false
                    width: parent.width
                }

                contentItem: BalanceItem {
                    balance: account.balances[asset_field.currentIndex]
                }
            }
        }

        AddressField {
            id: address_field
            Layout.fillWidth: true
            label: qsTr("id_recipient")

            onOpenScanner: {
                camera.start()
                stack_view.push(scanner_view)
            }
        }

        AmountField {
            id: amount_field
            Layout.fillWidth: true
            currency: 'BTC'
            label: qsTr('id_amount')
            enabled: !send_all_button.checked

            Binding on amount {
                when: send_all_button.checked && wallet.network.liquid
                value: asset_field_loader.item.balance.inputAmount
            }

            Binding on amount {
                when: send_all_button.checked && !wallet.network.liquid
                value: wallet.formatAmount(account.balance, false, wallet.settings.unit)
            }
        }

        Switch {
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
}
