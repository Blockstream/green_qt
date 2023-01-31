import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    property string icon
    property bool showRejectButton: true
    property bool enableRejectButton: true
    readonly property bool hovered: background_hover_handler.hovered
    id: self
    focus: true
    clip: true
    modal: true
    padding: constants.p3
    topPadding: constants.p1
    bottomPadding: constants.p1
    leftPadding: constants.p3
    rightPadding: constants.p3
    horizontalPadding: 0
    verticalPadding: 16
    anchors.centerIn: parent
    parent: Overlay.overlay
    spacing: 0
    header: DialogHeader {
        Image {
            Layout.maximumWidth: 32
            Layout.maximumHeight: 32
            fillMode: Image.PreserveAspectFit
            source: self.icon
            visible: self.icon && self.icon !== ''
        }
        Label {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            Layout.minimumWidth: 400
            text: title
            font.pixelSize: 22
            font.styleName: 'Medium'
            elide: Label.ElideRight
            ToolTip.text: title
            ToolTip.visible: truncated && title_hover_handler.hovered
            HoverHandler {
                id: title_hover_handler
            }
        }
        GToolButton {
            visible: self.showRejectButton
            enabled: self.enableRejectButton
            flat: true
            icon.source: 'qrc:/svg/cancel.svg'
            onClicked: self.reject()
            ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
            ToolTip.text: qsTrId('id_cancel')
            ToolTip.visible: hovered
        }
    }
    Overlay.modal: Rectangle {
        color: '#d0000000'
    }
    background: Rectangle {
        radius: 16
        color: constants.c800
        border.color: Qt.rgba(0, 0, 0, 0.5)
        HoverHandler {
            id: background_hover_handler
        }
    }
}
