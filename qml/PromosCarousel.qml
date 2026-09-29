import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

ColumnLayout {
    required property Context context
    required property Flickable flickable
    property var impressedPromoIds: ({})
    property var promos: []
    readonly property var eligiblePromos: {
        if (Settings.useTor) return []
        return [...PromoManager.promos]
            .filter(promo => !promo.dismissed)
            .filter(promo => UtilJS.filterPromo(WalletManager.wallets, promo))
    }

    function refreshPromos() {
        const next = self.eligiblePromos
        const previous = self.promos
        if (next.length === previous.length && next.every((promo, i) => promo === previous[i])) return
        const current_index = promo_swipe_view.currentIndex
        let index = next.indexOf(previous[current_index])
        if (index < 0) index = Math.min(Math.max(current_index, 0), next.length - 1)
        self.promos = next
        Qt.callLater(self.showPromo, index)
    }

    function showPromo(index) {
        if (self.promos.length === 0) return
        promo_swipe_view.currentIndex = Math.max(0, Math.min(index, self.promos.length - 1))
        Qt.callLater(self.recordCurrentImpression)
    }

    function dismissPromo(promo) {
        Analytics.recordEvent(
            'promo_dismiss',
            AnalyticsJS.segmentationPromo(null, promo, 'WalletOverview'))
        promo.dismiss()
    }

    function isInViewport() {
        const top = self.mapToItem(self.flickable, 0, 0).y
        const bottom = top + promo_swipe_view.height
        const visible_height = Math.min(bottom, self.flickable.height) - Math.max(top, 0)
        return visible_height >= promo_swipe_view.height / 2
    }

    function recordCurrentImpression() {
        if (!self.visible || !self.isInViewport()) return
        const promo = self.promos[promo_swipe_view.currentIndex]
        if (!promo || self.impressedPromoIds[promo.id]) return
        self.impressedPromoIds[promo.id] = true
        Analytics.recordEvent(
            'promo_impression',
            AnalyticsJS.segmentationPromo(null, promo, 'WalletOverview'))
    }

    Component.onCompleted: self.refreshPromos()
    id: self
    spacing: 8
    visible: self.promos.length > 0
    onEligiblePromosChanged: Qt.callLater(self.refreshPromos)
    onVisibleChanged: Qt.callLater(self.recordCurrentImpression)
    onYChanged: Qt.callLater(self.recordCurrentImpression)

    Connections {
        target: self.flickable
        function onContentYChanged() {
            Qt.callLater(self.recordCurrentImpression)
        }
        function onHeightChanged() {
            Qt.callLater(self.recordCurrentImpression)
        }
    }

    SwipeView {
        Layout.fillWidth: true
        id: promo_swipe_view
        clip: true
        interactive: self.promos.length > 1
        padding: 0
        spacing: 12
        onCurrentIndexChanged: Qt.callLater(self.recordCurrentImpression)

        Repeater {
            model: self.promos
            delegate: PromoCard {
                required property Promo modelData
                context: self.context
                promo: modelData
                screen: 'WalletOverview'
                onDismissRequested: self.dismissPromo(modelData)
            }
        }
    }

    WheelHandler {
        property real accumulatedDelta: 0
        property bool stepped: false
        id: wheel_handler
        enabled: self.promos.length > 1
        orientation: Qt.Horizontal
        target: null
        onWheel: (wheel) => {
            const dx = wheel.pixelDelta.x !== 0 ? wheel.pixelDelta.x : wheel.angleDelta.x
            const dy = wheel.pixelDelta.y !== 0 ? wheel.pixelDelta.y : wheel.angleDelta.y
            if (Math.abs(dx) <= Math.abs(dy)) {
                wheel.accepted = false
                return
            }
            wheel_gesture_timer.restart()
            if (wheel_handler.stepped && Math.sign(dx) !== Math.sign(wheel_handler.accumulatedDelta)) {
                wheel_handler.accumulatedDelta = 0
                wheel_handler.stepped = false
            }
            if (wheel_handler.stepped) return
            wheel_handler.accumulatedDelta += dx
            if (Math.abs(wheel_handler.accumulatedDelta) < 40) return
            self.showPromo(promo_swipe_view.currentIndex + (wheel_handler.accumulatedDelta > 0 ? -1 : 1))
            wheel_handler.stepped = true
        }
    }

    Timer {
        id: wheel_gesture_timer
        interval: 250
        onTriggered: {
            wheel_handler.accumulatedDelta = 0
            wheel_handler.stepped = false
        }
    }

    Row {
        Layout.alignment: Qt.AlignHCenter
        spacing: 8
        visible: self.promos.length > 1

        Repeater {
            model: self.promos.length
            delegate: AbstractButton {
                required property int index
                id: dot
                focusPolicy: Qt.StrongFocus
                implicitHeight: 8
                implicitWidth: 8
                padding: 0
                onClicked: self.showPromo(dot.index)
                background: Rectangle {
                    border.color: '#00BCFF'
                    border.width: dot.visualFocus ? 1 : 0
                    color: '#FFFFFF'
                    opacity: dot.index === promo_swipe_view.currentIndex ? 1 : 0.35
                    radius: 4
                }
            }
        }
    }
}
