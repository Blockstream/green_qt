import Blockstream.Green
import Blockstream.Green.Core
import QtMultimedia
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS

AbstractDrawer {
    required property var promo
    required property Context context
    required property string screen
    onClosed: self.destroy()
    id: self
    edge: Qt.RightEdge
    background: Loader {
        sourceComponent: bg1
    }
    contentItem: Loader {
        sourceComponent: comp1
    }
    Component {
        id: comp1
        ColumnLayout {
            spacing: 10
            CloseButton {
                Layout.alignment: Qt.AlignRight
                Layout.rightMargin: 20
                Layout.topMargin: 20
                onClicked: self.close()
            }
            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                id: overline_large
                font.pixelSize: 12
                font.weight: 300
                font.capitalization: Font.AllUppercase
                horizontalAlignment: Label.AlignHCenter
                text: self.promo.data.overline_large ?? ''
                textFormat: Label.RichText
                wrapMode: Label.WrapAtWordBoundaryOrAnywhere
                visible: overline_large.text.length > 0
            }
            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                id: title_large
                font.pixelSize: 24
                font.weight: 700
                horizontalAlignment: Label.AlignHCenter
                text: self.promo.data.title_large ?? ''
                wrapMode: Label.WrapAtWordBoundaryOrAnywhere
                visible: title_large.text.length > 0
            }
            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                id: text_large
                font.pixelSize: 12
                font.weight: 400
                horizontalAlignment: Label.AlignHCenter
                opacity: 0.8
                text: self.promo.data.text_large ?? ''
                textFormat: Label.RichText
                wrapMode: Label.WrapAtWordBoundaryOrAnywhere
                visible: text_large.text.length > 0
            }
            VSpacer {
            }
            PrimaryButton {
                Layout.fillWidth: true
                Layout.bottomMargin: 20
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                text: self.promo.data.cta_large
                onClicked: {
                    Analytics.recordEvent('promo_action', AnalyticsJS.segmentationPromo(Settings, self.context, self.promo, self.screen))
                    Qt.openUrlExternally(self.promo.data.link)
                    self.close()
                }
            }
        }
    }

    Component {
        id: bg1
        Rectangle {
            color: 'black'
            Video {
                id: video
                anchors.fill: parent
                autoPlay: true
                fillMode: VideoOutput.PreserveAspectCrop
                loops: MediaPlayer.Infinite
                muted: true
                source: self.promo.getOrCreateResource('video_large').path
                onPlaybackStateChanged: {
                    console.log('playback state changed', video.playbackState)
                }
                onStopped: {
                    console.log('video stopped')
                    video.play()
                }
            }
            Image {
                id: image
                anchors.fill: parent
                horizontalAlignment: Image.AlignHCenter
                fillMode: Image.PreserveAspectCrop
                source: self.promo.getOrCreateResource('image_large').path
                visible: image.status === Image.Ready
            }
            Rectangle {
                color: '#FFF'
                opacity: 0.1
                width: 1
                height: parent.height
            }
        }
    }
}
