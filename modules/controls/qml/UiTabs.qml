import QtQuick
import QtQuick.Controls.Basic as Basic

Basic.TabBar {
    property int lastEnabledIndex: 0

    function nextEnabledIndex(from, direction) {
        for (let step = 1; step < self.count; ++step) {
            const index = (from + direction * step + self.count * 10) % self.count
            if (self.itemAt(index)?.enabled) return index
        }
        return from
    }

    id: self
    implicitHeight: Math.max(60, self.contentHeight)
    spacing: 0
    padding: 0
    Accessible.role: Accessible.PageTabList
    background: null

    // TabBar can still land on a disabled tab via arrow keys; skip to the next enabled one.
    onCurrentIndexChanged: {
        if (self.currentIndex < 0 || self.currentIndex >= self.count) return
        const item = self.itemAt(self.currentIndex)
        if (!item) return
        if (item.enabled) {
            self.lastEnabledIndex = self.currentIndex
            return
        }
        const direction = self.currentIndex >= self.lastEnabledIndex ? 1 : -1
        const next = self.nextEnabledIndex(self.lastEnabledIndex, direction)
        if (next !== self.currentIndex) {
            self.setCurrentIndex(next)
        }
    }
}
