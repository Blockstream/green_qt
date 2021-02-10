import QtQuick 2.14
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.13

Dialog {
    id: self
    clip: true
    modal: true
    padding: 0
    topPadding: 8
    bottomPadding: 16
    leftPadding: 16
    rightPadding: 16
    horizontalPadding: 0
    verticalPadding: 8
    anchors.centerIn: parent
    parent: Overlay.overlay
    spacing: 0
    header: RowLayout {
        ToolButton {
            enabled: false
            icon.source: self.icon
            icon.color: "white"
            icon.width: 16
            icon.height: 16
        }
        Label {
            Layout.fillWidth: true
            text: title
            font.capitalization: Font.AllUppercase
            font.pixelSize: 20
            font.styleName: 'Light'
        }
        ToolButton {
            flat: true
            icon.source: 'qrc:/svg/cancel.svg'
            icon.width: 16
            icon.height: 16
            onClicked: self.reject()
        }
    }
    Overlay.modal: Rectangle {
        color: '#c0080B0E'
    }
    background: Rectangle {
        radius: 8
        color: constants.c700
    }

    property string icon: ""
}
