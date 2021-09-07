import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.12

MainPage {
    readonly property string url: 'https://blockstream.com/green/'
    readonly property var recentWallets: {
        const wallets = []
        // Force update when wallets are added/removed
        WalletManager.wallets
        for (const id of Settings.recentWallets) {
            const wallet = WalletManager.wallet(id)
            if (!wallet) continue
            if (wallet.network.key === 'testnet' && !Settings.enableTestnet) continue
            if (wallet.network.key === 'testnet-liquid' && (!Settings.enableTestnet || build_type === 'release')) continue
            wallets.push(wallet)
            if (wallets.length === 3) break
        }
        return wallets
    }

    AppUpdateController {
        id: app_update_controller
        onUpdateAvailableChanged: if (updateAvailable) notification_panel.y = constants.p1
        Component.onCompleted: if (Settings.checkForUpdates) checkForUpdates()
    }

    id: self
    header: GPane {
        id: header_pane
        padding: 24
        implicitHeight: 80
        background: null
        contentItem: Item {
            id: notification
            anchors.fill: parent
            clip: true

            RowLayout {
                anchors.fill: parent
                anchors.margins: constants.p1
                HSpacer {
                }
                GButton {
                    text: qsTrId('id_support')
                    highlighted: true
                    large: true
                    onClicked: Qt.openUrlExternally(constants.supportUrl)
                }
            }

            GPane {
                id: notification_panel
                x: constants.p1
                y: constants.p1 - parent.height
                width: parent.width - constants.p1*2
                implicitHeight: constants.p5
                padding: constants.p1
                scale: notification_panel.hovered ? 1.01 : 1
                transformOrigin: Item.Center
                Behavior on scale {
                    NumberAnimation {
                        easing.type: Easing.OutBack
                        duration: 400
                    }
                }
                background: Rectangle {
                    radius: 4
                    color: 'white'
                    MouseArea {
                        anchors.fill: parent
                        onClicked: Qt.openUrlExternally(constants.downloadUrl)
                    }
                }
                contentItem: RowLayout {
                    spacing: 12
                    Label {
                        text: qsTrId('There is a newer version of Green Desktop available')
                        color: 'black'
                    }
                    HSpacer {
                    }
                    Label {
                        text: qsTrId('Download %1').arg(app_update_controller.latestVersion)
                        font.bold: true
                        color: 'black'
                    }
                }

                Behavior on y {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }
    bottomPadding: 24
    contentItem: ColumnLayout {
        spacing: constants.p4
        Loader {
            Layout.rightMargin: 16
            Layout.fillWidth: true
            Layout.minimumHeight: 320
            active: Settings.showNews
            visible: active
            sourceComponent: NewsPage {
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 210
            Layout.maximumHeight: 230
            spacing: 12
            ColumnLayout {
                Layout.fillHeight: true
                Label {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 16
                    text: qsTrId('id_recently_used_wallets')
                    font.pixelSize: 18
                    font.bold: true
                }
                GPane {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    background: Rectangle {
                        color: constants.c800

                        Text {
                            visible: self.recentWallets.length === 0
                            text: qsTrId('id_looks_like_you_havent_used_a')
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
                                Layout.maximumWidth: parent.width
                                spacing: 12
                                icon.source: icons[wallet.network.key]
                                icon.color: 'transparent'
                                font.capitalization: Font.MixedCase
                                flat: true
                                text: wallet.name
                                onClicked: navigation.go(`/${wallet.network.key}/${wallet.id}`)
                            }
                        }
                    }
                }
            }
            Spacer {
            }
            ColumnLayout {
                Layout.rightMargin: 16
                Layout.fillHeight: true
                Label {
                    Layout.bottomMargin: 16
                    text: qsTrId('id_add_another_wallet')
                    font.pixelSize: 18
                    font.bold: true
                }
                GPane {
                    Layout.minimumWidth: 200
                    Layout.fillHeight: true
                    background: Rectangle {
                        color: constants.c800
                    }
                    contentItem: ColumnLayout {
                        GButton {
                            Layout.fillWidth: true
                            large: true
                            text: qsTrId('id_create_wallet')
                            font.capitalization: Font.MixedCase
                            onClicked: navigation.go('/signup')
                        }
                        GButton {
                            Layout.fillWidth: true
                            large: true
                            text: qsTrId('id_add_an_amp_wallet')
                            font.capitalization: Font.MixedCase
                            onClicked: navigation.go('/signup?network=liquid&type=amp')
                        }
                        GButton {
                            Layout.fillWidth: true
                            large: true
                            text: qsTrId('id_restore_wallet')
                            font.capitalization: Font.MixedCase
                            onClicked: navigation.go('/restore')
                        }
                    }
                }
            }
        }
        VSpacer {
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
            background: MouseArea {
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
