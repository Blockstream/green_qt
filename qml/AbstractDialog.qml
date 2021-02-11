import QtQuick 2.14
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.13

Dialog {
    id: self
    clip: true
    modal: true
    padding: 16
    topPadding: 16
    bottomPadding: 16
    leftPadding: 16
    rightPadding: 16
    horizontalPadding: 0
    verticalPadding: 8
    anchors.centerIn: parent
    parent: Overlay.overlay
    spacing: 0
    header: Pane {
        padding: self.padding
        background: Item {
        }
        contentItem: RowLayout {
            spacing: 8
            Image {
                source: self.icon
                sourceSize.width: 16
                sourceSize.height: 16
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
    }
    Overlay.modal: Rectangle {
        color: '#c0080B0E'
    }
    background: Rectangle {
        radius: 16
        color: constants.c700
    }

    property string icon: ""
}
