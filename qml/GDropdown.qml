import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

AbstractButton {
    id: self
    property var model: []
    property string textRole: 'text'
    property string valueRole: 'value'
    property var currentValue: null
    property var popupItem: null
    
    leftPadding: 12
    rightPadding: 12
    topPadding: 8
    bottomPadding: 8
    
    signal valueChanged(var value)
    
    function findCurrentIndex() {
        if (!self.model || self.model.length === 0) return -1
        for (let i = 0; i < self.model.length; i++) {
            const item = self.model[i]
            const value = typeof item === 'object' ? item[self.valueRole] : item
            if (value === self.currentValue) return i
        }
        return -1
    }
    
    function getDisplayText() {
        if (!self.model || self.model.length === 0) return ''
        const index = self.findCurrentIndex()
        if (index < 0) return ''
        const item = self.model[index]
        if (typeof item === 'object') {
            return item[self.textRole] || item[self.valueRole] || ''
        }
        return String(item)
    }
    
    background: Rectangle {
        color: '#FFFFFF'
        radius: 4
        opacity: 0.2
        visible: self.hovered || self.popupItem
    }
    
    contentItem: RowLayout {
        spacing: 4
        opacity: 0.7
        Label {
            Layout.alignment: Qt.AlignCenter
            text: self.getDisplayText()
        }
        Image {
            Layout.alignment: Qt.AlignCenter
            source: 'qrc:/svg2/caret-down-white.svg'
        }
    }
    
    onClicked: {
        if (self.popupItem) {
            self.popupItem.close()
            return
        }
        
        const popup = menu_component.createObject(self)
        self.popupItem = popup
        popup.closed.connect(() => { 
            self.popupItem = null
            popup.destroy()
        })
        popup.open()
    }
    
    Component {
        id: menu_component
        GMenu {
            id: menu
            x: (parent?.width ?? 0) - menu.width
            y: (parent?.height ?? 0) + 8
            padding: 8
            spacing: 4
            pointerX: 1
            pointerXOffset: -(parent?.width ?? 0) / 2
            maximumHeight: 300
            
            Repeater {
                model: self.model
                delegate: AbstractButton {
                    id: item_button
                    required property var modelData
                    required property int index
                    leftPadding: 12
                    rightPadding: 12
                    topPadding: 8
                    bottomPadding: 8
                    Layout.fillWidth: true
                    checkable: false
                    background: Rectangle {
                        color: '#FFF'
                        radius: 8
                        opacity: 0.2
                        visible: item_button.hovered
                    }
                    contentItem: RowLayout {
                        spacing: 12
                        Label {
                            Layout.alignment: Qt.AlignCenter
                            Layout.fillWidth: true
                            color: '#FFF'
                            font.pixelSize: 14
                            font.weight: 400
                            text: {
                                const item = item_button.modelData
                                if (typeof item === 'object') {
                                    return item[self.textRole] || item[self.valueRole] || ''
                                }
                                return String(item)
                            }
                        }
                        Image {
                            Layout.alignment: Qt.AlignCenter
                            source: 'qrc:/svg2/check.svg'
                            opacity: {
                                const item = item_button.modelData
                                const value = typeof item === 'object' ? item[self.valueRole] : item
                                return value === self.currentValue ? 1 : 0
                            }
                        }
                    }
                    onClicked: {
                        const item = item_button.modelData
                        const value = typeof item === 'object' ? item[self.valueRole] : item
                        if (value !== self.currentValue) {
                            self.currentValue = value
                            self.valueChanged(value)
                        }
                        menu.close()
                    }
                }
            }
        }
    }
}

