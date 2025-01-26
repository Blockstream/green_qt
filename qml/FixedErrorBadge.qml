import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Collapsible {
    Layout.minimumWidth: 400
    id: self
    property color backgroundColor: '#69302E'
    property bool pointer: true
    property var error
    function raise(error, details) {
        console.log('raise error', error, details)
        self.error = { error, details }
    }
    function clear() {
        self.error = undefined
    }
    onErrorChanged: {
        if (self.error) {
            const error = self.error?.error ?? self.error ?? ''
            const details = self.error?.details ?? ''
            error_label.text = error.startsWith('id_') ? qsTrId(error) : error
            details_label.text = details.startsWith('id_') ? qsTrId(details) : details
        }
    }
    animationVelocity: 200
    collapsed: !self.error
    Pane {
        width: self.width
        topPadding: 12
        bottomPadding: 12
        leftPadding: 16
        rightPadding: 16
        background: Rectangle {
            radius: 4
            color: self.backgroundColor
            Item {
                visible: pointer
                x: parent.width / 2
                Rectangle {
                    width: 8
                    height: 8
                    rotation: 45
                    color: constants.r500
                    transformOrigin: Item.Center
                    anchors.centerIn: parent
                }
            }
        }
        contentItem: RowLayout {
            ColumnLayout {
                Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    id: error_label
                    color: '#FFF'
                    font.pixelSize: 14
                    font.weight: 600
                    wrapMode: Label.Wrap
                }
                Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    id: details_label
                    color: '#FFF'
                    font.pixelSize: 12
                    font.weight: 400
                    opacity: 0.6
                    visible: details_label.text !== ''
                    wrapMode: Label.Wrap
                }
            }
            CloseButton {
                Layout.alignment: Qt.AlignCenter
                onClicked: self.clear()
            }
        }
    }
}
