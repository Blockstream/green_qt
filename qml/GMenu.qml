import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts

Popup {
    property real pointerX: 0.5
    property real pointerXOffset: 0
    property real pointerY: 0
    default property alias contentItemData: content_item.data
    id: menu
    font.pixelSize: 14
    font.weight: 400
    padding: 0
    spacing: 0
    background: Item {
        MultiEffect {
            anchors.fill: r
            shadowBlur: 1.0
            shadowColor: 'black'
            shadowEnabled: true
            shadowVerticalOffset: 0
            source: r
            blurMax: 64
        }
        Rectangle {
            id: pointer
            rotation: 45
            x: menu.pointerX * parent.width - pointer.width * 0.5 + menu.pointerXOffset
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
    contentItem: Flickable {
        ScrollIndicator.vertical: ScrollIndicator {
        }
        clip: true
        contentHeight: content_item.height
        contentWidth: content_item.implicitWidth
        implicitHeight: Math.min(content_item.implicitHeight, 300)
        implicitWidth: content_item.implicitWidth
        ColumnLayout {
            id: content_item
            spacing: self.spacing ?? 0
        }
    }

    component Item: AbstractButton {
        id: self

        property bool hideIcon: false
        property var details: {
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
            spacing: 0
            Image {
                Layout.preferredHeight: 24
                Layout.preferredWidth: 24
                Layout.rightMargin: 12
                fillMode: Image.PreserveAspectFit
                source: self.icon.source
                opacity: self.enabled ? 1 : 0.25
                visible: !self.hideIcon
            }
            Label {
                Layout.fillWidth: true
                text: self.details?.text ?? ''
                font: self.font
            }
            Label {
                Layout.leftMargin: 12
                background: Rectangle {
                    color: 'black'
                    radius: height / 2
                    opacity: 0.25
                }
                text: self.details?.count ?? ''
                visible: (self.details?.count ?? 0)
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
