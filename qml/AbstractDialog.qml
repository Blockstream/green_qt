import QtQuick 2.14
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.13

Dialog {
    property string icon
    property bool showRejectButton: true
    property bool enableRejectButton: true
    id: self
    focus: true
    clip: true
    modal: true
    padding: constants.p3
    topPadding: constants.p3
    bottomPadding: constants.p3
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
            font.pixelSize: 18
            font.styleName: 'Medium'
            elide: Label.ElideRight
            ToolTip.text: title
            ToolTip.visible: truncated && mouse_area.containsMouse
            background: MouseArea {
                id: mouse_area
                hoverEnabled: true
            }
        }
        ToolButton {
            padding: 0
            background: null
            visible: self.showRejectButton
            enabled: self.enableRejectButton
            flat: true
            icon.source: 'qrc:/svg/cancel.svg'
            icon.width: 16
            icon.height: 16
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
    }
}
