import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    spacing: constants.s1
    required property SignMessageResolver resolver
    VSpacer {
    }
    MultiImage {
        Layout.alignment: Qt.AlignHCenter
        foreground: 'qrc:/png/jade_7.png'
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
