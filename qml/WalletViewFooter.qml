import Blockstream.Green.Core 0.1
import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.12

GPane {
    required property Wallet wallet
    id: self
    topPadding: 8
    bottomPadding: 8
    leftPadding: 24
    rightPadding: 24
    focusPolicy: Qt.ClickFocus
    background: Rectangle {
        color: constants.c800
    }
    contentItem: RowLayout {
        spacing: constants.s2
        RowLayout {
            spacing: constants.s0
            Layout.fillWidth: false
            Image {
                fillMode: Image.PreserveAspectFit
                sourceSize.height: 16
                sourceSize.width: 16
                source: icons[self.wallet.network.key]
            }
            Label {
                text: wallet.network.displayName + ' ' + qsTrId('id_network')
                font.pixelSize: 12
            }
        }
        RowLayout {
            spacing: constants.s0
            Layout.fillWidth: false
            Image {
                fillMode: Image.PreserveAspectFit
                sourceSize.height: 16
                sourceSize.width: 16
                source: wallet.network.electrum ? 'qrc:/svg/key.svg' : 'qrc:/svg/multi-sig.svg'
            }
            Label {
                text: wallet.network.electrum ? qsTrId('id_singlesig') : qsTrId('id_multisig_shield')
                font.pixelSize: 12
            }
        }
        HSpacer {
        }
        Loader {
            active: wallet.session.useTor
            visible: active
            sourceComponent: RowLayout {
                spacing: 8
                Image {
                    fillMode: Image.PreserveAspectFit
                    Layout.maximumHeight: 16
                    Layout.maximumWidth: 16
                    mipmap: true
                    source: 'qrc:/svg/torV2.svg'
                }
                Label {
                    font.pixelSize: 12
                    text: qsTrId('id_tor')
                }
            }
        }
        Loader {
            active: 'type' in wallet.deviceDetails
            visible: active
            sourceComponent: DeviceBadge {
                device: wallet.device
                details: wallet.deviceDetails
                background: MouseArea {
                    enabled: wallet.device
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        const device = wallet.device
                        if (device.type === Device.BlockstreamJade) {
                            navigation.go(`/jade/${device.uuid}`)
                        } else if (device.vendor === Device.Ledger) {
                            navigation.go(`/ledger/${device.uuid}`)
                        }
                    }
                }
            }
        }
        Loader {
            property string unit: {
                const unit = wallet.settings.unit.toLowerCase()
                return unit === '\u00B5btc' ? 'ubtc' : unit
            }

            property var amount: {
                const ticker = wallet.events.ticker
                const pricing = wallet.settings.pricing;
                for (let value = 1; ; value = value * 10) {
                    const data = { [unit]: String(value) }
                    const result = wallet.convert(data);
                    if (!result.fiat || Number(result.fiat) >= 1) return result
                }
            }
            active: Settings.enableExperimental && amount.fiat
            sourceComponent: RowLayout {
                spacing: 8
                Image {
                    fillMode: Image.PreserveAspectFit
                    Layout.maximumHeight: 16
                    Layout.maximumWidth: 16
                    mipmap: true
                    source: {
                        if (wallet.network.liquid) {
                            return wallet.getOrCreateAsset(wallet.network.policyAsset).icon
                        } else {
                            return icons[self.wallet.network.key]
                        }
                    }
                }
                Label {
                    font.pixelSize: 12
                    text: `${Number(amount[unit])} ${wallet.displayUnit} ≈ ${amount.fiat} ${wallet.network.mainnet ? amount.fiat_currency : 'FIAT'}`
                }
            }
        }
    }
}
