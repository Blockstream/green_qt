import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Popup {
    property real pointerX: 0.5
    property real pointerY: 0
    default property alias contentItemData: content_item.data
    id: menu
    padding: 0
    background: Item {
        DropShadow {
            opacity: 0.5
            verticalOffset: 8
            radius: 32
            samples: 16
            source: r
            anchors.fill: r
        }
        Rectangle {
            id: pointer
            rotation: 45
            x: menu.pointerX * parent.width - pointer.width * 0.5
            y: menu.pointerY * parent.height - pointer.height * 0.5
            color: '#343842'
            width: 9
            height: 9
        }
        Rectangle {
            id: r
            color: '#222226'
            border.color: '#343842'
            border.width: 0.5
            radius: 10
            anchors.fill: parent
        }
        Rectangle {
            rotation: 45
            anchors.centerIn: pointer
            color: '#222226'
            width: 7.5
            height: 7.5
        }
    }
    contentItem: ColumnLayout {
        id: content_item
        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: content_item.width
                height: content_item.height
                radius: 9
            }
        }
        spacing: 0
    }

    component Item: AbstractButton {
        id: self

        readonly property var details: {
            const re = /^([^\(\)]+)(?: \((\d+)\))?$/
            const result = re.exec(self.text || '') || []
            const [_, text, count] = result
            return { text, count: Number(count ?? '0') }
        }

        Layout.fillWidth: true
        leftPadding: 24
        rightPadding: 24
        topPadding: 8
        bottomPadding: 8
        background: Rectangle {
            color: 'white'
            opacity: 0.05
            visible: self.enabled && self.hovered
        }

        contentItem: RowLayout {
            spacing: 12
            Image {
                Layout.preferredHeight: 24
                Layout.preferredWidth: 24
                fillMode: Image.PreserveAspectFit
                source: self.icon.source
                opacity: self.enabled ? 1 : 0.25
            }
            Label {
                Layout.fillWidth: true
                text: self.details?.text ?? ''
                font.pixelSize: 14
                font.weight: 400
            }
            Label {
                background: Rectangle {
                    color: 'black'
                    radius: height / 2
                    opacity: 0.25
                }
                text: self.details?.count ?? ''
                visible: (self.details?.count ?? 0) > 0
                topPadding: 4
                bottomPadding: 4
                leftPadding: 12
                rightPadding: 12
                font.pixelSize: 12
                font.weight: 400
                font.bold: true
            }
        }
    }

    component Separator: Rectangle {
        Layout.fillWidth: true
        Layout.minimumHeight: 1
        Layout.maximumHeight: 1
        color: 'white'
        opacity: 0.05
    }
}
