import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Loader {
    id: self

    required property AnalyticsAlert alert
    property bool dismissed: false

    readonly property bool ancestorsVisible: {
        let item = parent
        while (item) {
            if (!item.visible) return false
            item = item.parent
        }
        return true
    }

    onAncestorsVisibleChanged: {
        if (ancestorsVisible) {
            self.dismissed = false
        }
    }

    active: alert && alert.active && !dismissed
    visible: active

    Layout.fillWidth: true

    sourceComponent: Page {
        implicitWidth: 0
        leftPadding: 16
        rightPadding: 16
        background: Rectangle {
            radius: 4
            color: 'white'
        }
        header: Label {
            text: self.alert.title
            font.bold: true
            color: '#080B0E'
            padding: 16
        }
        contentItem: Label {
            text: self.alert.message
            wrapMode: Label.WordWrap
            color: '#12171E'
        }
        footer: RowLayout {
            LinkButton {
                Layout.margins: 16
                font.bold: true
                font.pixelSize: 14
                text: qsTrId('id_learn_more')
                external: true
                onClicked: Qt.openUrlExternally(self.alert.link)
            }
            HSpacer {
            }
            LinkButton {
                Layout.margins: 16
                font.bold: true
                font.pixelSize: 14
                text: 'Dismiss'
                visible: self.alert.dismissable
                onClicked: self.dismissed = true
            }
        }
    }
}
