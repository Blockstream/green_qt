import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

Page {
    property Balance balance

    background: null

    header: RowLayout {
        spacing: constants.p2
        ToolButton {
            id: back_arrow_button
            icon.source: 'qrc:/svg/arrow_left.svg'
            icon.height: 16
            icon.width: 16
            onClicked: account_view.pop()
        }

        Label {
            text: qsTrId("id_asset_details")
            font.pixelSize: 16
            font.capitalization: Font.AllUppercase
            Layout.fillWidth: true
        }

        GButton {
            Layout.rightMargin: constants.p1
            text: qsTrId('id_view_in_explorer')
            onClicked: balance.asset.openInExplorer()
        }
    }

    contentItem: ScrollView {
        id: scroll_view
        clip: true

        ColumnLayout {
            width: scroll_view.width - constants.p2
            spacing: constants.p2

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
            SectionLabel {
                text: qsTrId('id_ticker')
                visible: 'ticker' in balance.asset.data
            }
            CopyableLabel {
                text: balance.asset.data.ticker
                visible: 'ticker' in balance.asset.data
            }
            SectionLabel {
                text: qsTrId('id_issuer')
                visible: 'entity' in balance.asset.data
            }
            CopyableLabel {
                text: balance.asset.data.entity.domain
                visible: 'entity' in balance.asset.data
            }
            SectionLabel {
                text: qsTrId('id_total_balance')
            }
            CopyableLabel {
                text: balance.displayAmount
            }
            SectionLabel {
                    text: qsTrId('id_asset_id')
            }
            CopyableLabel {
                text: balance.asset.id
            }
        }
    }
}
