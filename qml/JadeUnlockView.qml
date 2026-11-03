import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

StackViewPage {
    signal unlockFinished(Context context)
    signal unlockFailed()
    required property Context context
    required property JadeDevice device
    property bool showRemember: true
    readonly property bool connected: controller.context?.sessions?.[0]?.connected ?? false

    JadeUnlockController {
        id: controller
        context: self.context
        device: self.device
        onHttpRequest: (request) => {
            const dialog = http_request_dialog.createObject(self, { request, context: self.context })
            dialog.open()
        }
        onUnlocked: (context) => self.unlockFinished(context)
        onInvalidPin: self.unlockFailed()
        onDisconnected: self.unlockFailed()
    }

    StackView.onActivated: controller.unlock()
    id: self
    title: 'Unlock Jade'
    rightItem: CloseButton {
        onClicked: self.closeClicked()
    }
    contentItem: ColumnLayout {
    spacing: 20
        VSpacer {
        }
        MultiImage {
            Layout.alignment: Qt.AlignCenter
            width: 200
            height: 240
            foreground: UtilJS.jadeImage(self.device, 7)
        }
        Label {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            color: '#FFFFFF'
            font.pixelSize: 22
            font.weight: 600
            horizontalAlignment: Label.AlignHCenter
            text: qsTrId('id_unlock_your_device_to_continue')
            wrapMode: Label.WordWrap
        }
        BusyIndicator {
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 10
        }
        VSpacer {
        }
    }
    Component {
        id: http_request_dialog
        JadeHttpRequestDialog {
        }
    }
}
