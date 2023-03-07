import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Window
import Qt5Compat.GraphicalEffects

import "analytics.js" as AnalyticsJS

StackLayout {
    id: self
    required property string title
    required property string network
    readonly property string location: `/${network}`
    readonly property WalletView currentWalletView: {
        for (let i = 0; i < wallet_view_repeater.count; ++i) {
            const view = wallet_view_repeater.itemAt(i)
            if (view.match) return view
        }
        return null
    }
    readonly property bool active: {
        if (window.navigation.param.view === self.network) return true
        const wallet = WalletManager.wallet(window.navigation.param.wallet)
        if (wallet && wallet.context && wallet.network.key === self.network) return true
        return false
    }

    currentIndex: {
        let index = 0
        for (let i = 0; i < wallet_view_repeater.count; ++i) {
            if (wallet_view_repeater.itemAt(i).match) {
                return 1 + i
            }
        }
        return index
    }

    MainPage {
        id: page
        header: MainPageHeader {
            background: Rectangle {
                color: constants.c700
                opacity: wallet_list_view.contentY > 0 ? 1 : 0
                Behavior on opacity {
                    SmoothedAnimation {
                        velocity: 4
                    }
                }

                FastBlur {
                    anchors.fill: parent
                    cached: true
                    opacity: 0.55

                    radius: 128
                    source: ShaderEffectSource {
                        sourceItem: page.contentItem
                        sourceRect {
                            x: -page.contentItem.x
                            y: -page.contentItem.y
                            width: page.header.width
                            height: page.header.height
                        }
                    }
                }
                Rectangle {
                    width: parent.width
                    height: 1
                    y: parent.height - 1
                    color: constants.c900
                }
            }

            contentItem: RowLayout {
                spacing: 16
                Label {
                    text: self.title
                    font.pixelSize: 24
                    font.styleName: 'Medium'
                    Layout.fillWidth: true
                }
                GButton {
                    text: qsTrId('id_create_new_wallet')
                    highlighted: true
                    onClicked: {
                        if (self.network.liquid) {
                            navigation.set({ flow: 'signup', network: self.network })
                        } else {
                            navigation.set({ flow: 'signup', network: self.network, type: 'default' })
                        }
                    }
                }
                GButton {
                    text: qsTrId('id_restore_green_wallet')
                    onClicked: navigation.set({ flow: 'restore', network: self.network })
                }
                GButton {
                    text: qsTrId('id_watchonly_login')
                    onClicked: navigation.set({ flow: 'watch_only_login', network: self.network })
//                    onClicked: watch_only_login_dialog.createObject(window).open()
                }
            }
        }
        footer: StatusBar {
            contentItem: RowLayout {
                SessionBadge {
                    session: HttpManager.session
                }
            }
        }


//        Component {
//            id: watch_only_login_dialog
//            WatchOnlyLoginDialog {
//                network: NetworkManager.networkWithServerType(self.network, 'green')
//            }
//        }

        contentItem: GPane {
            background: Item {
                Label {
                    anchors.centerIn: parent
                    visible: wallet_list_view.count === 0
                    text: qsTrId('id_looks_like_you_havent_used_a');
                }
            }
            contentItem: TListView {
                id: wallet_list_view
                currentIndex: -1
                model: WalletListModel {
                    network: self.network
                }
                delegate: WalletListDelegate {
                    width: ListView.view.contentWidth
                }
            }
        }
    }

    Repeater {
        id: wallet_view_repeater
        model: WalletListModel {
            justAuthenticated: true
            network: self.network
        }
        delegate: WalletView {
            property bool match: navigation.param.wallet === wallet.id
            context: wallet.context
            AnalyticsView {
                name: 'Overview'
                segmentation: AnalyticsJS.segmentationSession(wallet)
                active: match
            }
        }
    }

    component TListView: ListView {
        ScrollIndicator.vertical: ScrollIndicator { }
        contentWidth: width
        displayMarginBeginning: 300
        displayMarginEnd: 100
    }
}
