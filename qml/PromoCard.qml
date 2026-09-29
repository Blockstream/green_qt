import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Window

import "analytics.js" as AnalyticsJS

AbstractButton {
    signal dismissRequested()

    required property Context context
    required property Promo promo
    required property string screen

    function openPromo() {
        const url = self.promo?.data?.cta?.url ?? ''
        if (!url) return
        Analytics.recordEvent('promo_action', AnalyticsJS.segmentationPromo(self.context, self.promo, self.screen))
        Qt.openUrlExternally(url)
    }

    id: self
    clip: true
    focusPolicy: Qt.StrongFocus
    hoverEnabled: true
    implicitHeight: 164
    padding: 24
    rightPadding: Math.round(self.width * 0.44)
    onClicked: self.openPromo()

    background: Rectangle {
        border.color: self.visualFocus ? '#00BCFF' : '#262626'
        border.width: self.visualFocus ? 2 : 1
        color: Qt.lighter('#181818', self.enabled && self.hovered ? 1.08 : 1)
        radius: 4
    }

    contentItem: ColumnLayout {
        spacing: 8

        Label {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            color: '#F5F5F5'
            elide: Text.ElideRight
            font.pixelSize: 16
            font.weight: 600
            maximumLineCount: 1
            text: self.promo?.data?.title ?? ''
            textFormat: Text.PlainText
            wrapMode: Text.NoWrap
        }

        Label {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            color: '#A0A0A0'
            elide: Text.ElideRight
            font.pixelSize: 14
            font.weight: 400
            maximumLineCount: 3
            text: self.promo?.data?.description ?? ''
            textFormat: Text.PlainText
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        }

        Item {
            Layout.fillHeight: true
        }

        LinkButton {
            Layout.maximumWidth: parent.width
            external: true
            text: self.promo?.data?.cta?.label ?? ''
            onClicked: self.openPromo()
        }
    }

    Item {
        id: image_slot
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.top: parent.top
        width: Math.max(0, self.rightPadding - 8)

        Rectangle {
            anchors.centerIn: parent
            color: '#164347'
            height: 116
            opacity: 0.75
            radius: width / 2
            visible: promo_image.status !== Image.Ready
            width: 148
            layer.enabled: true
            layer.effect: MultiEffect {
                autoPaddingEnabled: true
                blur: 1
                blurEnabled: true
                blurMax: 48
            }
        }

        Rectangle {
            anchors.centerIn: parent
            color: '#414345'
            height: 72
            opacity: 0.65
            radius: width / 2
            visible: promo_image.status !== Image.Ready
            width: 96
            layer.enabled: true
            layer.effect: MultiEffect {
                autoPaddingEnabled: true
                blur: 1
                blurEnabled: true
                blurMax: 32
            }
        }

        Image {
            id: promo_image
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.margins: 8
            anchors.right: parent.right
            anchors.top: parent.top
            asynchronous: true
            fillMode: Image.PreserveAspectFit
            horizontalAlignment: Image.AlignHCenter
            mipmap: true
            smooth: true
            source: self.promo?.getOrCreateResource('imageUrl')?.path ?? ''
            sourceSize.height: Math.round(148 * Screen.devicePixelRatio)
            verticalAlignment: Image.AlignVCenter
            visible: status === Image.Ready
        }
    }

    CloseButton {
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.top: parent.top
        anchors.topMargin: 14
        height: 20
        width: 20
        onClicked: self.dismissRequested()
    }

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }
}
