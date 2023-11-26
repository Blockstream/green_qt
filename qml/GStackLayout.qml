import QtQuick
import QtQuick.Layouts

StackLayout {
    readonly property Item currentItem: self.children[self.currentIndex] ?? null
    id: self
}
