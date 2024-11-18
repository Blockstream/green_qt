import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS

Pane {
    signal assetsClicked()
    signal promoClicked(Promo promo)
    required property Context context
    id: self
    clip: true
    leftPadding: 16
    rightPadding: 16
    topPadding: 0
    bottomPadding: 0
    background: Rectangle {
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.04)
        color: '#161921'
        radius: 8
    }
    contentItem: Flickable {
        id: flickable
        implicitHeight: layout.implicitHeight
        contentWidth: layout.implicitWidth
        RowLayout {
            id: layout
            spacing: 0
            TotalBalanceCard {
                context: self.context
            }
            Separator {
                visible: assets_card.visible
            }
            AssetsCard {
                id: assets_card
                context: self.context
                header.enabled: false
                background: Rectangle {
                    color: '#FFF'
                    opacity: 0.04
                    visible: hover_handler.hovered
                }
                HoverHandler {
                    id: hover_handler
                    parent: assets_card
                }
                TapHandler {
                    parent: assets_card
                    onTapped: self.assetsClicked()
                }
            }
            Separator {
                visible: jade_card.visible
            }
            JadeCard {
                id: jade_card
                context: self.context
            }
            Separator {
            }
            PriceCard {
                context: self.context
            }
            Separator {
                visible: fee_rate_card.visible
            }
            FeeRateCard {
                id: fee_rate_card
                context: self.context
            }
            Separator {
            }
            RowLayout {
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: false
                visible: promos_repeater.count > 0
                Repeater {
                    id: promos_repeater
                    model: {
                        return [...PromoManager.promos]
                            .filter(promo => !promo.dismissed)
                            .filter(promo => promo.data.is_visible)
                            .filter(promo => promo.data.screens.indexOf('WalletOverview') >= 0)
                            .slice(0, 1)
                    }
                    delegate: PromoCard {
                        required property Promo modelData
                        Layout.minimumWidth: 400
                        id: delegate
                        context: self.context
                        promo: delegate.modelData
                    }
                }
            }
        }
    }
    Image {
        source: 'qrc:/svg2/arrow_right.svg'
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        visible: flickable.contentX > 0
        rotation: 180
        opacity: 0.5
        TapHandler {
            onTapped: flickable.flick(2000, 0)
        }
    }
    Image {
        source: 'qrc:/svg2/arrow_right.svg'
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        visible: flickable.contentWidth - flickable.contentX > flickable.width
        opacity: 0.5
        TapHandler {
            onTapped: flickable.flick(-2000, 0)
        }
    }

    component Separator: Rectangle {
        Layout.minimumWidth: 1
        Layout.maximumWidth: 1
        Layout.fillHeight: true
        color: '#FFF'
        opacity: 0.04
    }

    component PromoCard: WalletHeaderCard {
        required property Promo promo
        Component.onCompleted: {
            Analytics.recordEvent('promo_impression', AnalyticsJS.segmentationPromo(Settings, self.context, self.promo, 'WalletOverview'))
        }
        id: self
        padding: 16
        background: Item {
            Image {
                id: image
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                fillMode: Image.PreserveAspectFit
                height: 100
                horizontalAlignment: Image.AlignRight
                verticalAlignment: Image.AlignTop
                source: self.promo.data.image_small ?? ''
                visible: image.status === Image.Ready
            }
        }
        spacing: 0
        header: RowLayout {
            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 16
                Layout.topMargin: 16
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
                    Analytics.recordEvent('promo_dismiss', AnalyticsJS.segmentationPromo(Settings, self.context, self.promo, 'WalletOverview'))
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
                font.pixelSize: 16
                font.weight: 600
                padding: 12
                leftPadding: 14
                rightPadding: 14
                topPadding: 2
                bottomPadding: 2
                text: self.promo.data.cta_small
                onClicked: {
                    if (self.promo.data.is_small) {
                        Analytics.recordEvent('promo_action', AnalyticsJS.segmentationPromo(Settings, self.context, self.promo, 'WalletOverview'))
                        Qt.openUrlExternally(self.promo.data.link)
                    } else {
                        Analytics.recordEvent('promo_open', AnalyticsJS.segmentationPromo(Settings, self.context, self.promo, 'WalletOverview'))
                        self.promoClicked(self.promo)
                    }
                }
            }
        }
    }
}
