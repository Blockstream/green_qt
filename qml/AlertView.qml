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
        leftPadding: constants.p2
        rightPadding: constants.p2
        background: Rectangle {
            radius: 4
            color: 'white'
        }
        header: Label {
            text: self.alert.title
            font.bold: true
            color: constants.c900
            padding: constants.p2
        }
        contentItem: Label {
            text: self.alert.message
            wrapMode: Label.WordWrap
            color: constants.c800
        }
        footer: RowLayout {
            LinkButton {
                Layout.margins: constants.p2
                font.bold: true
                font.pixelSize: 14
                text: qsTrId('id_learn_more')
                onClicked: Qt.openUrlExternally(self.alert.link)
            }
            HSpacer {
            }
            LinkButton {
                Layout.margins: constants.p2
                font.bold: true
                font.pixelSize: 14
                text: 'Dismiss'
                visible: self.alert.dismissable
                onClicked: self.dismissed = true
            }
        }
    }
}
