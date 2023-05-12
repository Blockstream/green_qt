import Blockstream.Green.Core
import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

StatusBar {
    required property Context context
    required property Wallet wallet
    readonly property Network network: context.network
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
                text: self.network.displayName + ' ' + qsTrId('id_network')
                font.pixelSize: 12
            }
        }
        HSpacer {
        }
        SessionBadge {
            session: self.context.session
        }
        Loader {
            active: 'type' in self.wallet.deviceDetails || self.context.device
            visible: active
            sourceComponent: DeviceBadge {
                device: self.context.device
                details: self.wallet.deviceDetails
                TapHandler {
                    enabled: self.context.device
                    cursorShape: Qt.PointingHandCursor
                    onTapped: {
                        const device = self.context.device
                        console.log('click man')
                        console.log(self.context, device)
                        if (device.type === Device.BlockstreamJade) {
                            window.navigation.push({ view: 'jade', device: device.uuid })
                        } else if (device.vendor === Device.Ledger) {
                            window.navigation.push({ view: 'ledger', device: device.uuid })
                        }
                    }
                }
            }
        }
        Loader {
            property string unit: {
                const unit = self.context.unit.toLowerCase()
                return unit === '\u00B5btc' ? 'ubtc' : unit
            }

            property var amount: {
                const ticker = self.context.events.ticker
                const pricing = self.context.settings.pricing;
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
                        if (self.network.liquid) {
                            return self.context.getOrCreateAsset(self.network.policyAsset).icon
                        } else {
                            return UtilJS.iconFor(self.wallet)
                        }
                    }
                }
                Label {
                    font.pixelSize: 12
                    text: `${Number(amount[unit])} ${self.context.displayUnit} ≈ ${amount.fiat} ${self.network.mainnet ? amount.fiat_currency : 'FIAT'}`
                }
            }
        }
    }
}
