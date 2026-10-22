import QtQuick
import QtQuick.Templates as T

QtObject {
    required property T.Popup popup
    property string accessibleId: ''
    property int role: Accessible.Grouping
    property bool ready: false

    readonly property Binding idBinding: Binding {
        target: self.ready ? self.popup.contentItem : null
        property: 'Accessible.id'
        value: self.accessibleId
        when: self.ready && self.popup.contentItem !== null
    }
    readonly property Binding roleBinding: Binding {
        target: self.ready ? self.popup.contentItem : null
        property: 'Accessible.role'
        // Cocoa flattens popup menus and reserves window roles for native windows.
        value: {
            if (Qt.platform.os !== 'osx') return self.role
            if (self.role === Accessible.PopupMenu || self.role === Accessible.Dialog) return Accessible.Grouping
            return self.role
        }
        when: self.ready && self.popup.contentItem !== null && self.accessibleId.length > 0
    }

    id: self
    // Resolve targets during completion, after caller-supplied content is assigned.
    Component.onCompleted: self.ready = true
}
