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
        anchors.leftMargin: 20
        clip: true

        Column {
            width: scroll_view.width - 20
            spacing: 16

            Column {
                spacing: 10
                Label {
                    opacity: 0.5
                    text: qsTrId('id_name')
                    font.pixelSize: 14
                }

                Row {
                    spacing: 10
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
            }

            Column {
                Label {
                    opacity: 0.5
                    text: qsTrId('id_ticker')
                    font.pixelSize: 14
                }
                Label {
                    text: balance.asset.data.ticker
                    font.pixelSize: 16
                }
            }

            Column {
                Label {
                    opacity: 0.5
                    text: qsTrId('id_issuer')
                    font.pixelSize: 14
                }

                Label {
                    text: balance.asset.data.entity.domain
                    font.pixelSize: 16
                }
            }

            Column {
                Label {
                    opacity: 0.5
                    text: qsTrId('id_total_balance')
                    font.pixelSize: 14
                }
                Label {
                    text: balance.displayAmount
                    font.pixelSize: 16
                }
            }

            Column {
                Label {
                    opacity: 0.5
                    text: qsTrId('id_asset_id')
                    font.pixelSize: 14
                }
                Label {
                    text: balance.asset.id
                    font.pixelSize: 16
                }
            }

            Column {
                Label {
                    opacity: 0.5
                    text: qsTrId('id_precision')
                    font.pixelSize: 14
                }
                Label {
                    text: balance.asset.data.precision
                    font.pixelSize: 16
                }
            }
        }
    }
}
