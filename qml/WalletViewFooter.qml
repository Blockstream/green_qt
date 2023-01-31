import Blockstream.Green.Core
import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

StatusBar {
    required property Wallet wallet
    id: self
    contentItem: RowLayout {
        spacing: constants.s2
        RowLayout {
            spacing: constants.s0
            Layout.fillWidth: false
            Image {
                fillMode: Image.PreserveAspectFit
                sourceSize.height: 16
                sourceSize.width: 16
                source: UtilJS.iconFor(self.wallet)
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
        SessionBadge {
            session: wallet.session
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
            active: amount.fiat
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
                            return UtilJS.iconFor(self.wallet)
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
