import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts

Dialog {
    required property var promo
    onClosed: self.destroy()
    id: self
    clip: true
    modal: true
    anchors.centerIn: parent
    topPadding: 20
    bottomPadding: 20
    leftPadding: 20
    rightPadding: 20
    Overlay.modal: MultiEffect {
        anchors.fill: parent
        autoPaddingEnabled: false
        brightness: self.visible ? -0.05 : 0
        Behavior on brightness {
            NumberAnimation { duration: 200 }
        }
        blurEnabled: true
        blurMax: 64
        blur: self.visible ? 1 : 0
        Behavior on blur {
            NumberAnimation { duration: 200 }
        }
        source: ApplicationWindow.contentItem
    }
    background: Rectangle {
        color: '#13161D'
        radius: 10
        border.width: 1
        border.color: Qt.alpha('#FFFFFF', 0.07)
    }
    header: RowLayout {
        CloseButton {
            Layout.alignment: Qt.AlignRight
            Layout.rightMargin: 20
            Layout.topMargin: 20
            onClicked: self.close()
        }
    }
    footer: RowLayout {
        PrimaryButton {
            Layout.fillWidth: true
            Layout.bottomMargin: 20
            Layout.leftMargin: 20
            Layout.rightMargin: 20
            text: self.promo.data.cta_large
            onClicked: {
                Qt.openUrlExternally(self.promo.data.link)
                self.close()
            }
        }
    }
    contentItem: ColumnLayout {
        Image {
            Layout.fillWidth: true
            Layout.maximumHeight: 350
            Layout.minimumWidth: 400
            Layout.preferredWidth: 0
            id: image
            horizontalAlignment: Image.AlignHCenter
            fillMode: Image.PreserveAspectFit
            source: self.promo.data.image_large
            visible: image.status === Image.Ready
        }
        Label {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            id: title_large
            font.pixelSize: 14
            font.weight: 600
            horizontalAlignment: Label.AlignHCenter
            text: self.promo.data.title_large ?? ''
            wrapMode: Label.WrapAtWordBoundaryOrAnywhere
            visible: title_large.text.length > 0
        }
        Label {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            id: text_large
            text: self.promo.data.text_large ?? ''
            textFormat: Label.RichText
            wrapMode: Label.WrapAtWordBoundaryOrAnywhere
            visible: text_large.text.length > 0
        }
    }
}
