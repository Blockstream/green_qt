import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

StackViewPage {
    readonly property int delayInterval: 15 * 1000
    readonly property bool suspended: self.StackView.status !== StackView.Active

    property bool delayed: false
    property bool paused: true
    property int remaining: self.delayInterval
    property double resumedAt: 0

    function start() {
        delay_timer.stop()
        self.delayed = false
        self.paused = true
        self.remaining = self.delayInterval
        self.resumedAt = 0
        self.resume()
    }

    function pause() {
        if (self.delayed || self.paused) return
        self.remaining = Math.max(0, self.remaining - (Date.now() - self.resumedAt))
        delay_timer.stop()
        self.paused = true
    }

    function resume() {
        if (self.suspended || self.delayed || !self.paused) return
        if (self.remaining <= 0) {
            self.delayed = true
            return
        }
        self.paused = false
        self.resumedAt = Date.now()
        delay_timer.interval = Math.max(1, self.remaining)
        delay_timer.restart()
    }

    id: self
    padding: 60
    // Keep invisible back button to avoid layout shift on loading page transition
    leftItem: BackButton {
        visible: false
    }
    onSuspendedChanged: {
        if (self.suspended) {
            self.pause()
        } else {
            self.resume()
        }
    }
    Component.onCompleted: self.start()

    ColumnLayout {
        Layout.alignment: Qt.AlignCenter
        Layout.fillHeight: false
        Layout.fillWidth: true
        spacing: 20

        BusyIndicator {
            Layout.alignment: Qt.AlignCenter
        }

        ColumnLayout {
            spacing: 8
            Label {
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                font.pixelSize: 22
                font.weight: 600
                horizontalAlignment: Label.AlignHCenter
                text: self.delayed ? 'Login is taking longer than usual' : qsTrId('id_logging_in')
                wrapMode: Label.WordWrap
            }
            LinkLabel {
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                font.pixelSize: 16
                color: '#A0A0A0'
                horizontalAlignment: Label.AlignHCenter
                text: `More information: ${UtilJS.link('https://status.blockstream.com', 'status.blockstream.com')}`
                visible: self.delayed
                wrapMode: Label.WordWrap
            }
        }
    }

    Timer {
        id: delay_timer
        interval: self.delayInterval
        onTriggered: {
            self.delayed = true
            self.paused = false
            self.remaining = 0
        }
    }
}
