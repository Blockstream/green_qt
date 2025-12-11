import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts

Dialog {
    property string icon
    property bool showRejectButton: true
    property bool enableRejectButton: true
    id: self
    focus: true
    modal: true
    padding: 24
    topPadding: 12
    bottomPadding: 24
    leftPadding: 24
    rightPadding: 24
    horizontalPadding: 0
    verticalPadding: 64
    anchors.centerIn: parent
    parent: Overlay.overlay
    spacing: 0
    z: 2
    header: DialogHeader {
        Image {
            Layout.maximumWidth: 24
            Layout.maximumHeight: 24
            fillMode: Image.PreserveAspectFit
            source: self.icon
            visible: self.icon && self.icon !== ''
        }
        Label {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            Layout.minimumWidth: 200
            text: title
            font.pixelSize: 20
            font.styleName: 'Medium'
        }
        CloseButton {
            visible: self.showRejectButton
            enabled: self.enableRejectButton
            onClicked: self.reject()
        }
    }

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
        radius: 10
        color: Qt.alpha('#232323', 0.95)
        border.width: 1
        border.color: '#383838'
    }
}
