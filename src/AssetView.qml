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
            icon.source: 'assets/svg/arrow_left.svg'
            icon.height: 16
            icon.width: 16
            onClicked: stack_view.pop()
        }

        AssetIcon {
            asset: balance.asset
        }

        Label {
            text: balance.asset.name
            font.pixelSize: 16
            font.capitalization: Font.AllUppercase
            Layout.fillWidth: true
        }
        Button {
            Layout.rightMargin: 32
            flat: true
            text: qsTr('id_view_in_explorer')
            onClicked: Qt.openUrlExternally(`https://blockstream.info/liquid/asset/${balance.asset.id}`)
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
                Label {
                    opacity: 0.5
                    text: qsTr('id_asset_id')
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
                    text: qsTr('id_total_balance')
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
                    text: qsTr('id_precision')
                    font.pixelSize: 14
                }
                Label {
                    text: balance.asset.data.precision
                    font.pixelSize: 16
                }
            }

            Column {
                Label {
                    opacity: 0.5
                    text: qsTr('id_ticker')
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
                    text: qsTr('id_issuer')
                    font.pixelSize: 14
                }

                Label {
                    text: balance.asset.data.entity.domain
                    font.pixelSize: 16
                }
            }
        }
    }
}
