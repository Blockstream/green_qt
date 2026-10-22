import Blockstream.Theme
import QtQuick
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts

Basic.MenuItem {
    property Colors colors: Theme.colors
    property string iconName: ''
    property int count: 0

    id: self
    padding: 8
    leftPadding: 24
    rightPadding: 24
    font: Theme.typography.bodyM.font
    focusPolicy: Qt.StrongFocus
    hoverEnabled: true
    Accessible.name: self.count > 0 ? `${self.text} (${self.count})` : self.text
    arrow: null
    indicator: null
    background: Rectangle {
        color: self.enabled && (self.highlighted || self.hovered) ? self.colors.surfaceHover : 'transparent'
        border.color: self.colors.borderFocus
        border.width: self.visualFocus ? 2 : 0
    }
    contentItem: RowLayout {
        spacing: 12
        UiIcon {
            Layout.alignment: Qt.AlignVCenter
            name: self.iconName
            size: 24
            color: self.enabled ? self.colors.iconBase : self.colors.iconDisabled
        }
        UiLabel {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: 0
            text: self.text
            typography: Theme.typography.bodyM
            color: self.enabled ? self.colors.textPrimary : self.colors.textDisabled
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
            Accessible.ignored: true
        }
        UiLabel {
            Layout.alignment: Qt.AlignVCenter
            Layout.minimumWidth: 32
            visible: self.count > 0
            text: self.count
            typography: Theme.typography.labelSmSemibold
            color: self.colors.textPrimary
            topPadding: 4
            bottomPadding: 4
            leftPadding: 12
            rightPadding: 12
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            background: Rectangle {
                color: self.colors.surfaceBase
                radius: height / 2
            }
            Accessible.ignored: true
        }
    }
}
