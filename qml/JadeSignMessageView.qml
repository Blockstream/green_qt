import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    spacing: constants.s1
    required property SignMessageResolver resolver
    VSpacer {
    }
    Image {
        Layout.alignment: Qt.AlignHCenter
        source: 'qrc:/png/connect_jade_2.png'
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
