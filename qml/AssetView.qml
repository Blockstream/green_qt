import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

Page {
    property Balance balance

    background: Item {}

    header: RowLayout {
        spacing: 16
        ToolButton {
            id: back_arrow_button
            icon.source: '/svg/arrow_left.svg'
            icon.height: 16
            icon.width: 16
            onClicked: stack_view.pop()
        }

        Label {
            text: qsTrId("id_asset_details")
            font.pixelSize: 16
            font.capitalization: Font.AllUppercase
            Layout.fillWidth: true
        }

        Button {
            Layout.rightMargin: 32
            flat: true
            text: qsTrId('id_view_in_explorer')
            onClicked: balance.asset.openInExplorer()
        }
    }

    ScrollView {
        id: scroll_view
        anchors.fill: parent
        anchors.leftMargin: 16
        clip: true

        ColumnLayout {
            width: scroll_view.width - 16
            spacing: 16

            SectionLabel {
                text: qsTrId('id_name')
            }
            Row {
                spacing: 16
                AssetIcon {
                    id: icon
                    asset: balance.asset
                }
                Label {
                    text: balance.asset.name
                    font.pixelSize: 16
                    anchors.verticalCenter: icon.verticalCenter
                }
            }
            SectionLabel {
                    text: qsTrId('id_ticker')
            }
            Label {
                text: balance.asset.data.ticker
            }
            SectionLabel {
                text: qsTrId('id_issuer')
            }
            Label {
                text: balance.asset.data.entity.domain
            }
            SectionLabel {
                text: qsTrId('id_total_balance')
            }
            Label {
                text: balance.displayAmount
            }
            SectionLabel {
                    text: qsTrId('id_asset_id')
            }
            Label {
                text: balance.asset.id
            }
            SectionLabel {
                text: qsTrId('id_precision')
            }
            Label {
                text: balance.asset.data.precision
            }
        }
    }
}
