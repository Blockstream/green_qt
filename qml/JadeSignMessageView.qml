import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "jade.js" as JadeJS

ColumnLayout {
    signal signed
    signal failed
    required property SignMessageResolver resolver
    id: self
    spacing: constants.s1
    Connections {
        target: self.resolver
        function onResolved() {
            self.signed()
        }
        function onFailed() {
            self.failed()
        }
    }
    VSpacer {
    }
    MultiImage {
        Layout.alignment: Qt.AlignHCenter
        foreground: JadeJS.image(self.resolver.session.context.device, 7)
        width: 352
        height: 240
    }
    SectionLabel {
        text: qsTrId('id_message_hash')
    }
    Label {
        Layout.fillWidth: true
        Layout.preferredWidth: 0
        text: String(resolver.hash).match(/.{1,8}/g).join(' ')
        wrapMode: Text.Wrap
    }
    SectionLabel {
        Layout.fillWidth: true
        Layout.preferredWidth: 0
        text: qsTrId('id_path_used_for_signing')
        wrapMode: Text.Wrap
    }
    Label {
        text: resolver.path
    }
    VSpacer {
    }
}
