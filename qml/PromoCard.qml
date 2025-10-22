import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

Loader {
    signal clicked()
    required property string screen
    required property Promo promo
    id: self
    Component.onCompleted: {
        Analytics.recordEvent('promo_impression', AnalyticsJS.segmentationPromo(Settings, null, self.promo, self.screen))
    }
    sourceComponent: {
        switch (self.promo.data?.layout_small ?? 0) {
        case 0: return layout_0
        case 1: return layout_1
        case 2: return layout_2
        }
    }
    CloseButton {
        id: close_button
        z: 1
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 16
        onClicked: {
            Analytics.recordEvent('promo_dismiss', AnalyticsJS.segmentationPromo(Settings, null, self.promo, self.screen))
            self.promo.dismiss()
        }
    }
    Component {
        id: layout_0
        Page {
            bottomPadding: 12
            leftPadding: 24
            rightPadding: 24
            topPadding: 12
            background: Rectangle {
                radius: 4
                color: '#181818'
                border.width: 1
                border.color: '#262626'
            }
            footer: ColumnLayout {
                PrimaryButton {
                    Layout.fillWidth: true
                    Layout.margins: 0
                    Layout.leftMargin: 24
                    Layout.rightMargin: 24
                    Layout.bottomMargin: 12
                    text: self.promo.data.cta_small
                    onClicked: self.clicked()
                }
            }
            header: RowLayout {
                ColumnLayout {
                    Layout.margins: 0
                    Layout.leftMargin: 16
                    Layout.rightMargin: 0
                    Layout.topMargin: 16
                    spacing: 10
                    Label {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 0
                        id: title_label
                        font.pixelSize: 14
                        font.weight: 700
                        text: self.promo.data.title_small ?? ''
                        visible: title_label.text.length > 0
                        wrapMode: Label.WrapAtWordBoundaryOrAnywhere
                    }
                    Label {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 0
                        id: text_label
                        font.pixelSize: 12
                        font.weight: 400
                        verticalAlignment: Label.AlignTop
                        opacity: 0.8
                        text: self.promo.data.text_small ?? ''
                        textFormat: Label.RichText
                        visible: text_label.text.length > 0
                        wrapMode: Label.WrapAtWordBoundaryOrAnywhere
                    }
                }
                Image {
                    Layout.alignment: Qt.AlignTop | Qt.AlignRight
                    Layout.maximumHeight: 100
                    Layout.minimumWidth: image.paintedWidth
                    Layout.preferredWidth: 0
                    Layout.rightMargin: 16
                    id: image
                    source: self.promo.getOrCreateResource('image_small').path
                    fillMode: Image.PreserveAspectFit
                    verticalAlignment: Image.AlignTop
                    visible: image.status === Image.Ready
                }
            }
            contentItem: null
        }
    }
    Component {
        id: layout_1
        Pane {
            bottomPadding: 16
            leftPadding: 24
            rightPadding: 24
            topPadding: 0
            background: Rectangle {
                radius: 4
                color: '#181818'
                border.width: 1
                border.color: '#262626'
            }
            contentItem: ColumnLayout {
                spacing: 10
                Image {
                    Layout.alignment: Qt.AlignTop | Qt.AlignRight
                    Layout.fillWidth: true
                    Layout.preferredHeight: 0
                    Layout.minimumHeight: {
                        if (image.status !== Image.Ready) return 0
                        return image.sourceSize.height * image.width / image.sourceSize.width
                    }
                    Layout.maximumHeight: 200
                    id: image
                    source: self.promo.getOrCreateResource('image_small').path
                    fillMode: Image.PreserveAspectFit
                    verticalAlignment: Image.AlignTop
                    horizontalAlignment: Image.AlignHCenter
                    visible: image.status === Image.Ready
                }
                Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    id: title_label
                    font.pixelSize: 14
                    font.weight: 700
                    text: self.promo.data.title_small ?? ''
                    visible: title_label.text.length > 0
                    wrapMode: Label.WrapAtWordBoundaryOrAnywhere
                }
                Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    id: text_label
                    font.pixelSize: 12
                    font.weight: 400
                    verticalAlignment: Label.AlignTop
                    opacity: 0.8
                    text: self.promo.data.text_small ?? ''
                    textFormat: Label.RichText
                    visible: text_label.text.length > 0
                    wrapMode: Label.WrapAtWordBoundaryOrAnywhere
                }
                PrimaryButton {
                    Layout.fillWidth: true
                    text: self.promo.data.cta_small
                    onClicked: self.clicked()
                }
            }
        }
    }
    Component {
        id: layout_2
        Page {
            bottomPadding: 12
            leftPadding: 24
            rightPadding: 24
            topPadding: 12
            background: Rectangle {
                radius: 4
                color: '#181818'
                Image {
                    id: image
                    anchors.fill: parent
                    source: self.promo.getOrCreateResource('image_small').path
                    fillMode: Image.PreserveAspectCrop
                    verticalAlignment: Image.AlignTop
                    visible: image.status === Image.Ready
                }
                Rectangle {
                    anchors.fill: parent
                    radius: 4
                    color: 'transparent'
                    border.width: 1
                    border.color: '#262626'
                }
            }
            footer: ColumnLayout {
                PrimaryButton {
                    Layout.fillWidth: true
                    Layout.margins: 24
                    text: self.promo.data.cta_small
                    onClicked: self.clicked()
                }
            }
            header: ColumnLayout {
                Label {
                    Layout.margins: 16
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    id: overline_label
                    font.capitalization: Font.AllUppercase
                    font.pixelSize: 10
                    font.weight: 300
                    horizontalAlignment: Label.AlignHCenter
                    text: self.promo.data.overline_small
                    visible: overline_label.text.length > 0
                    wrapMode: Label.WrapAtWordBoundaryOrAnywhere
                }
                Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    Layout.leftMargin: 24
                    Layout.rightMargin: 24
                    id: title_label
                    font.pixelSize: 24
                    font.weight: 700
                    horizontalAlignment: Label.AlignHCenter
                    text: self.promo.data.title_small ?? ''
                    visible: title_label.text.length > 0
                    wrapMode: Label.WrapAtWordBoundaryOrAnywhere
                }
                Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    Layout.leftMargin: 24
                    Layout.rightMargin: 24
                    id: text_label
                    font.pixelSize: 12
                    font.weight: 400
                    horizontalAlignment: Label.AlignHCenter
                    verticalAlignment: Label.AlignTop
                    opacity: 0.8
                    text: self.promo.data.text_small ?? ''
                    textFormat: Label.RichText
                    visible: text_label.text.length > 0
                    wrapMode: Label.WrapAtWordBoundaryOrAnywhere
                }
            }
            contentItem: null
        }
    }
}
