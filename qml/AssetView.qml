import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

WalletDialog {
    required property Balance balance

    id: self
    title: qsTrId('id_asset_details')
    wallet: balance.account.wallet
    contentItem: ScrollView {
        id: scroll_view
        clip: true

        ColumnLayout {
            width: scroll_view.width - constants.p2
            spacing: constants.p3

            Row {
                spacing: constants.p2
                AssetIcon {
                    id: icon
                    asset: balance.asset
                }
                CopyableLabel {
                    text: balance.asset.name
                    font.pixelSize: 18
                    font.styleName: 'Medium'
                    anchors.verticalCenter: icon.verticalCenter
                }
            }

            ColumnLayout {
                spacing: constants.p0

                SectionLabel {
                    text: qsTrId('id_ticker')
                    visible: balance.asset.data.ticket
                }

                CopyableLabel {
                    text: balance.asset.data.ticker
                    visible: balance.asset.data.ticker
                }
            }

            ColumnLayout {
                spacing: constants.p0

                SectionLabel {
                    text: qsTrId('id_issuer')
                    visible: balance.asset.data.entity
                }

                CopyableLabel {
                    text: balance.asset.data.entity.domain
                    visible: balance.asset.data.entity
                }
            }

            ColumnLayout {
                spacing: constants.p0

                SectionLabel {
                    text: qsTrId('id_total_balance')
                }

                CopyableLabel {
                    text: balance.displayAmount
                }
            }

            ColumnLayout {
                spacing: constants.p0

                SectionLabel {
                    text: qsTrId('id_asset_id')
                }

                CopyableLabel {
                    text: balance.asset.id
                }
            }
            HSpacer { }
        }
    }

    footer: DialogFooter {
        HSpacer {
        }
        GButton {
            text: qsTrId('id_view_in_explorer')
            onClicked: balance.asset.openInExplorer()
        }
    }
}
