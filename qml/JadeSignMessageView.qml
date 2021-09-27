import Blockstream.Green 0.1
import QtQuick 2.13
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

ColumnLayout {
    spacing: constants.s1
    required property SignMessageResolver resolver
    Component.onCompleted: resolver.resolve()
    Label {
        text: qsTrId('id_verify_on_device')
    }
    SectionLabel {
        text: qsTrId('id_device')
    }
    RowLayout {
        Layout.fillHeight: false
        spacing: constants.s1
        DeviceImage {
            device: resolver.device
            sourceSize.height: 24
        }
        Label {
            Layout.fillWidth: true
            text: resolver.device.name
        }
    }
    SectionLabel {
        text: qsTrId('id_message')
    }
    Label {
        text: resolver.message
        wrapMode: Label.WrapAtWordBoundaryOrAnywhere
        Layout.maximumWidth: 500
    }
    SectionLabel {
        text: qsTrId('id_hash')
    }
    Label {
        text: resolver.hash
        wrapMode: Label.WrapAtWordBoundaryOrAnywhere
        Layout.maximumWidth: 500
    }
    SectionLabel {
        text: qsTrId('id_path')
    }
    Label {
        text: resolver.path
    }
}
