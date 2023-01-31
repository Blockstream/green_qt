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
        header: RowLayout {
            Label {
                text: self.alert.title
                font.bold: true
                color: constants.c900
                padding: constants.p2
                Layout.fillWidth: true
                Layout.preferredWidth: 0
            }
            AbstractButton {
                visible: self.alert.dismissable
                padding: constants.p2
                contentItem: Image {
                    source: 'qrc:/svg/cancel.svg'
                    width: 16
                    height: 16
                }
                onClicked: self.dismissed = true
            }
        }
        contentItem: Label {
            text: self.alert.message
            wrapMode: Label.WordWrap
            color: constants.c800
        }
        footer: Label {
            text: qsTrId('id_learn_more')
            color: 'green'
            font.bold: true
            wrapMode: Label.WordWrap
            padding: constants.p2
            TapHandler {
                onTapped: Qt.openUrlExternally(self.alert.link)
            }
        }
    }
}
