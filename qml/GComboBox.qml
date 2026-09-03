import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

pragma ComponentBehavior: Bound

ComboBox {
    id: self
    
    property real maxPopupHeight: 300
    property string iconRole
    property string checkedRole
    property url triggerIconSource
    property Component triggerContent
    property real triggerXPadding: xPadding
    property real triggerYPadding: yPadding
    readonly property real xPadding: 12
    readonly property real yPadding: 8
    
    leftPadding: triggerXPadding
    rightPadding: triggerXPadding
    topPadding: triggerYPadding
    bottomPadding: triggerYPadding
    
    // Disable default indicator to use custom one in contentItem
    indicator: Item {}
    
    background: Rectangle {
        color: '#FFF'
        radius: 4
        opacity: 0.2
        visible: self.hovered || self.popup.visible
    }
    
    contentItem: Loader {
        sourceComponent: self.triggerContent ?? default_trigger
    }

    Component {
        id: default_trigger
        RowLayout {
            spacing: 4
            opacity: 0.7
            Label {
                Layout.fillWidth: true
                text: self.displayText
                color: '#FFFFFF'
                font: self.font
            }
            Image {
                Layout.alignment: Qt.AlignCenter
                source: String(self.triggerIconSource).length > 0
                    ? self.triggerIconSource
                    : 'qrc:/svg2/caret-down-white.svg'
            }
        }
    }
    
    delegate: ItemDelegate {
        id: delegateItem
        required property int index
        required property var modelData
        
        leftPadding: self.xPadding
        rightPadding: self.xPadding
        topPadding: self.yPadding
        bottomPadding: self.yPadding
        width: listView.width
        highlighted: self.highlightedIndex === index
        
        background: Rectangle {
            color: '#FFFFFF'
            radius: 4
            opacity: 0.2
            visible: delegateItem.hovered || delegateItem.highlighted
        }
        
        contentItem: RowLayout {
            spacing: 12
            Image {
                Layout.alignment: Qt.AlignCenter
                Layout.preferredHeight: 24
                Layout.preferredWidth: 24
                fillMode: Image.PreserveAspectFit
                source: self.iconRole && delegateItem.modelData
                    ? delegateItem.modelData[self.iconRole] ?? ''
                    : ''
                visible: String(source).length > 0
            }
            Label {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignCenter
                color: '#FFFFFF'
                font.pixelSize: 14
                font.weight: 400
                text: {
                    if (!delegateItem.modelData) return ''
                    return self.textRole ? delegateItem.modelData[self.textRole] ?? '' : delegateItem.modelData
                }
            }
            Image {
                Layout.alignment: Qt.AlignCenter
                Layout.maximumWidth: 16
                Layout.maximumHeight: 16
                source: 'qrc:/svg2/check.svg'
                opacity: self.checkedRole && delegateItem.modelData
                    ? (delegateItem.modelData[self.checkedRole] ? 1 : 0)
                    : (self.currentIndex === delegateItem.index ? 1 : 0)
            }
        }
    }
    
    popup: Popup {
        id: popupItem
        x: self.width - width
        y: self.height + self.yPadding
        padding: 0
        implicitHeight: Math.min(contentItem.implicitHeight, self.maxPopupHeight)
        width: self.width + self.xPadding * 2

        background: Rectangle {
            color: '#262626'
            border.color: '#343842'
            border.width: 0.5
            radius: 8
        }
        
        contentItem: Item {
            implicitHeight: listView.implicitHeight + self.yPadding * 2
            
            ListView {
                id: listView
                anchors.fill: parent
                anchors.margins: 8
                
                model: self.delegateModel
                currentIndex: self.highlightedIndex
                highlightMoveDuration: 0
                clip: true
                implicitHeight: Math.min(contentHeight, self.maxPopupHeight - 2 * self.yPadding)
                spacing: 4
                
                ScrollBar.vertical: ScrollBar {
                    id: scrollbar
                    parent: listView.parent
                    
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    
                    policy: ScrollBar.AlwaysOn
                    visible: listView.contentHeight > listView.height
                    opacity: 0.3
                    
                    background: Rectangle {
                        color: 'transparent'
                        implicitWidth: 2
                    }

                    contentItem: Rectangle {
                        implicitWidth: 2
                        color: '#FFFFFF'
                        radius: 1
                    }
                }
            }
        }
    }
}
