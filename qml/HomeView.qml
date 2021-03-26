import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.12

MainPage {
    readonly property string url: 'https://blockstream.com/green/'
    readonly property var recentWallets: {
        const wallets = []
        for (const id of Settings.recentWallets) {
            const wallet = WalletManager.wallet(id)
            if (wallet) wallets.push(wallet)
        }
        return wallets
    }
    id: self
    header: Pane {
        padding: 24
        background: null
        contentItem: RowLayout {
            Label {
                text: 'Welcome back!'
                font.pixelSize: 24
                font.styleName: 'Medium'
            }
            Item {
                Layout.fillWidth: true
                height: 1
            }
            Button {
                text: 'id_support'
                opacity: 0
                flat: true
            }
        }
    }
    bottomPadding: 24
    contentItem: ColumnLayout {       
        Image {
            Layout.topMargin: 24
            Layout.bottomMargin: 24
            Layout.alignment: Qt.AlignHCenter
            source: 'qrc:/svg/green_logo.svg'
            sourceSize.height: 96
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 210
            Layout.maximumHeight: 210
            spacing: 12
            ColumnLayout {
                Layout.fillHeight: true
                Label {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 16
                    text: "Recently Used Wallets"
                    font.pixelSize: 18
                    font.bold: true
                }
                Pane {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    background: Rectangle {
                        color: constants.c800

                        Text {
                            visible: self.recentWallets.length === 0
                            text: "Looks like you haven't used a wallet yet."
                            color: 'white'
                            anchors.centerIn: parent
                        }
                    }
                    contentItem: ColumnLayout {
                        spacing: 0
                        Repeater {
                            model: self.recentWallets
                            Button {
                                readonly property Wallet wallet: modelData
                                Layout.alignment: Qt.AlignLeft
                                spacing: 12
                                icon.source: icons[wallet.network.id]
                                icon.color: 'transparent'
                                font.capitalization: Font.MixedCase
                                flat: true
                                text: wallet.name
                                onClicked: pushLocation(`/${wallet.network.id}/${wallet.id}`)
                            }
                        }
                    }
                }
            }
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
            ColumnLayout {
                Layout.rightMargin: 16
                Layout.fillHeight: true
                Label {
                    Layout.bottomMargin: 16
                    text: "Add Another Wallet"
                    font.pixelSize: 18
                    font.bold: true
                }
                Pane {
                    Layout.minimumWidth: 200
                    Layout.fillHeight: true
                    background: Rectangle {
                        color: constants.c800
                    }
                    contentItem: ColumnLayout {
                        Button {
                            Layout.fillWidth: true
                            flat: true
                            text: 'Create Wallet'
                            font.capitalization: Font.MixedCase
                            onClicked: {
                                var obj = chooose_network.createObject(window, { title: 'Create Wallet' })
                                obj.networkSelected.connect((network) => { pushLocation(`/${network}/signup`) })
                                obj.open()
                            }
                        }
                        Button {
                            Layout.fillWidth: true
                            flat: true
                            text: 'Restore Wallet'
                            font.capitalization: Font.MixedCase
                            onClicked: {
                                var obj = chooose_network.createObject(window, { title: 'Restore Wallet' })
                                obj.networkSelected.connect((network) => { pushLocation(`/${network}/restore`) })
                                obj.open()
                            }
                        }
                    }
                }
            }
        }
        Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: qsTrId('Copyright (©) 2021') + '<br/><br/>' +
                  qsTrId('id_version') + ' ' + Qt.application.version + '<br/><br/>' +
                  qsTrId('id_please_contribute_if_you_find') + ".<br/>" +
                  qsTrId('id_visit_s_for_further_information').arg(link(url)) + ".<br/><br/>" +
                  qsTrId('id_distributed_under_the_s_see').arg('GNU General Public License v3.0').arg(link('https://opensource.org/licenses/GPL-3.0'))
            textFormat: Text.RichText
            font.pixelSize: 12
            color: constants.c300
            onLinkActivated: Qt.openUrlExternally(link)
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
            }
        }
    }

    Component {
        id: chooose_network

        ChooseNetworkDialog {

        }
    }
}
