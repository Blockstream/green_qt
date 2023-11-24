import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Dialog {
    property string icon
    property bool showRejectButton: true
    property bool enableRejectButton: true
    readonly property bool hovered: background_hover_handler.hovered
    property Item toolbar: toolbar_item
    id: self
    focus: true
    modal: true
    padding: constants.p3
    topPadding: constants.p1
    bottomPadding: constants.p3
    leftPadding: constants.p3
    rightPadding: constants.p3
    horizontalPadding: 0
    verticalPadding: 64
    anchors.centerIn: parent
    parent: Overlay.overlay
    spacing: 0
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
            elide: Label.ElideRight
            ToolTip.text: title
            ToolTip.visible: truncated && title_hover_handler.hovered
            HoverHandler {
                id: title_hover_handler
            }
        }
        RowLayout {
            spacing: 4
            id: toolbar_item
        }
        CloseButton {
            visible: self.showRejectButton
            enabled: self.enableRejectButton
            onClicked: self.reject()
        }
    }

    Overlay.modal: Rectangle {
        id: modal
        color: constants.c900
        FastBlur {
            anchors.fill: parent
            cached: true
            opacity: 0.5
            radius: 64
            source: ShaderEffectSource {
                sourceItem: ApplicationWindow.contentItem
                sourceRect {
                    x: 0
                    y: 0
                    width: modal.width
                    height: modal.height
                }
            }
        }
    }

    background: Item {
        HoverHandler {
            id: background_hover_handler
        }
        DropShadow {
            opacity: 0.5
            verticalOffset: 8
            radius: 32
            samples: 16
            source: r
            anchors.fill: r
        }
        Rectangle {
            id: r
            anchors.fill: parent
            radius: 10
            color: '#13161D'
            border.width: 0.5
            border.color: Qt.lighter('#13161D')
        }
    }
}
