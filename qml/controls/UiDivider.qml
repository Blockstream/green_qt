import Blockstream.Theme
import QtQuick
import QtQuick.Layouts

Rectangle {
    enum Weight { Subtle, Bold }

    property int orientation: Qt.Horizontal
    property int weight: UiDivider.Subtle
    property Colors colors: Theme.colors

    readonly property bool horizontal: self.orientation !== Qt.Vertical

    id: self
    implicitWidth: self.horizontal ? 0 : 1
    implicitHeight: self.horizontal ? 1 : 0
    Layout.fillWidth: self.horizontal
    Layout.fillHeight: !self.horizontal
    Layout.maximumWidth: self.horizontal ? Number.POSITIVE_INFINITY : 1
    Layout.maximumHeight: self.horizontal ? 1 : Number.POSITIVE_INFINITY
    color: self.weight === UiDivider.Bold ? self.colors.borderBold : self.colors.borderSubtle
    Accessible.role: Accessible.Separator
}
