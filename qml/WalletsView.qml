import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

MainPage {
    signal openWallet(Wallet wallet)
    signal openDevice(Device device)
    signal createWallet
    readonly property int count: sww_repeater.count + hww_repeater.count
    readonly property var notifications: UtilJS.flatten(home_alert.notification)
    AnalyticsAlert {
        id: home_alert
        screen: 'Home'
    }
    id: self
    padding: 60
    title: qsTrId('id_wallets')
    contentItem: Flickable {
        ScrollIndicator.vertical: ScrollIndicator {
        }
        id: flickable
        clip: true
        contentHeight: layout.height
        contentWidth: flickable.width
        ColumnLayout {
            id: layout
            width: 400
            x: (flickable.width - 400) / 2
            y: Math.max(0, (flickable.height - layout.height) / 2)
            Label {
                font.pixelSize: 14
                font.weight: 600
                opacity: 0.4
                text: qsTrId('id_digital_wallets')
            }
            Hint {
                text: 'Your wallets with keys persisted on the Green app will appear here.'
                visible: sww_repeater.count === 0
            }
            Repeater {
                id: sww_repeater
                model: WalletListModel {
                    deviceDetails: WalletListModel.No
                }
                WalletsDrawer.WalletButton {
                    Layout.fillWidth: true
                    id: wallet_button
                    onClicked: self.openWallet(wallet_button.wallet)
                }
            }
            Label {
                Layout.topMargin: 20
                font.pixelSize: 14
                font.weight: 600
                opacity: 0.4
                text: qsTrId('id_hardware_devices')
            }
            Hint {
                text: 'Your wallets with keys persisted on a hardware device will appear here.'
                visible: hww_repeater.count === 0
            }
            Repeater {
                id: hww_repeater
                model: WalletListModel {
                    deviceDetails: WalletListModel.Yes
                    watchOnly: WalletListModel.No
                    pinData: WalletListModel.No
                }
                WalletsDrawer.WalletButton {
                    Layout.fillWidth: true
                    id: wallet_button
                    onClicked: self.openWallet(wallet_button.wallet)
                }
            }
        }
    }
    header: Pane {
        background: null
        padding: 60
        bottomPadding: 20
        contentItem: ColumnLayout {
            spacing: 20
            Image {
                Layout.alignment: Qt.AlignCenter
                source: 'qrc:/svg2/blockstream_green.svg'
            }
            RowLayout {
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: false
                visible: promos_repeater.count > 0
                Repeater {
                    id: promos_repeater
                    model: {
                        return [...PromoManager.promos]
                            .filter(_ => !Settings.useTor)
                            .filter(promo => !promo.dismissed)
                            .filter(promo => promo.data.is_visible)
                            .filter(promo => promo.data.screens.indexOf('Home') >= 0)
                            .slice(0, 1)
                    }
                    delegate: PromoDelegate {
                        required property Promo modelData
                        Layout.minimumWidth: 400
                        id: delegate
                        promo: delegate.modelData
                        onClicked: {
                            const context = null
                            const promo = delegate.promo
                            const screen = 'Home'
                            if (promo.data.is_small) {
                                Analytics.recordEvent('promo_action', AnalyticsJS.segmentationPromo(Settings, context, promo, screen))
                                Qt.openUrlExternally(promo.data.link)
                            } else {
                                Analytics.recordEvent('promo_open', AnalyticsJS.segmentationPromo(Settings, context, promo, screen))
                                promo_dialog.createObject(self.Window.window, { context, promo, screen }).open()
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: promo_dialog
        PromoDialog {
        }
    }

    component PromoDelegate: Page {
        signal clicked()
        required property Promo promo
        Component.onCompleted: {
            Analytics.recordEvent('promo_impression', AnalyticsJS.segmentationPromo(Settings, null, self.promo, 'Home'))
        }
        id: self
        padding: 16
        background: Rectangle {
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.04)
            color: '#161921'
            radius: 8
            Image {
                id: image
                anchors.top: parent.top
                anchors.topMargin: 16
                anchors.right: parent.right
                fillMode: Image.PreserveAspectFit
                height: 100
                horizontalAlignment: Image.AlignRight
                verticalAlignment: Image.AlignTop
                source: self.promo.data.image_small ?? ''
                visible: image.status === Image.Ready
            }
        }
        header: RowLayout {
            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                Layout.alignment: Qt.AlignVCenter
                Layout.minimumHeight: image.visible ? image.paintedHeight - 20 : null
                Layout.margins: 16
                Layout.maximumWidth: image.visible ? self.width - image.paintedWidth - 40 : null
                id: title_small
                font.pixelSize: 14
                font.weight: 600
                verticalAlignment: Label.AlignVCenter
                text: self.promo.data.title_small ?? ''
                wrapMode: Label.WrapAtWordBoundaryOrAnywhere
                visible: title_small.text.length > 0
            }
            CloseButton {
                Layout.margins: 16
                Layout.alignment: Qt.AlignRight | Qt.AlignTop
                onClicked: {
                    Analytics.recordEvent('promo_dismiss', AnalyticsJS.segmentationPromo(Settings, null, self.promo, 'Home'))
                    self.promo.dismiss()
                }
            }
        }
        contentItem: ColumnLayout {
            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                id: text_small
                text: self.promo.data.text_small ?? ''
                textFormat: Label.RichText
                wrapMode: Label.WrapAtWordBoundaryOrAnywhere
                visible: text_small.text.length > 0
            }
            PrimaryButton {
                Layout.fillWidth: true
                text: self.promo.data.cta_small
                onClicked: self.clicked()
            }
        }
    }
    footer: Pane {
        background: null
        padding: 60
        topPadding: 20
        contentItem: ColumnLayout {
            WalletsDrawer.ListButton {
                Layout.alignment: Qt.AlignCenter
                Layout.maximumWidth: 400
                contentItem: RowLayout {
                    spacing: 14
                    Label {
                        Layout.alignment: Qt.AlignCenter
                        Layout.fillWidth: true
                        Layout.preferredWidth: 0
                        font.pixelSize: 14
                        font.weight: 500
                        text:  qsTrId('id_setup_a_new_wallet')
                        elide: Label.ElideRight
                    }
                    Image {
                        Layout.alignment: Qt.AlignCenter
                        source: 'qrc:/svg2/right.svg'
                    }
                }
                onClicked: self.createWallet()
            }
        }
    }
}
