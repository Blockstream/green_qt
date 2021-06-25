import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.15
import QtQml 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQml.Models 2.0

GPane {
    id: self
    background: null
    contentItem: RowLayout {
        spacing: 24
        Card {
            server_type: 'electrum'
            icons: ['qrc:/svg/singleSig.svg']
            title: qsTrId('Singlesig')
            description: qsTrId('Your funds are secured by a single key held on your device. Simpler to set up and operate than multisig. If in doubt, select this option.')
        }
        Card {
            enabled: (navigation.param.type || '') !== 'amp'
            server_type: 'green'
            icons: ['qrc:/svg/home.svg']
            title: 'Multisig Shield'
            description: qsTrId('Your funds are secured by multiple keys, with one key on your device and another on our servers. For enhanced security.')
        }
        HSpacer {
        }
    }

    component Card: Button {
        id: self
        required property string server_type
        required property string type
        required property string title
        property string description
        property var icons
        Layout.minimumHeight: 160
        Layout.preferredWidth: 360
        padding: 24
        scale: self.hovered || self.activeFocus ? 1.05 : 1
        transformOrigin: Item.Center
        Behavior on scale {
            NumberAnimation {
                easing.type: Easing.OutBack
                duration: 400
            }
        }
        background: Rectangle {
            border.width: 1
            border.color: self.activeFocus ? constants.g400 : Qt.rgba(0, 0, 0, 0.2)
            radius: 8
            color: Qt.rgba(1, 1, 1, self.hovered ? 0.1 : 0.05)
            Behavior on color {
                ColorAnimation {
                    duration: 300
                }
            }
        }
        contentItem: ColumnLayout {
            spacing: 12
            RowLayout {
                spacing: 12
                Repeater {
                    model: self.icons
                    delegate: Image {
                        opacity: self.enabled ? 1 : 0.5
                        source: modelData
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                    }
                }
                Label {
                    Layout.fillWidth: true
                    text: self.title
                    font.bold: true
                    font.pixelSize: 20
                }
            }
            Label {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: self.description
                font.pixelSize: 12
                wrapMode: Label.WordWrap
            }
        }
        onClicked: navigation.set({ server_type: self.server_type })
    }

    component Section: Page {
        property color color
        id: self
        bottomPadding: 12
        header: Label {
            bottomPadding: 12
            topPadding: 12
            opacity: 0.5
            text: self.title
        }
        background: null
    }
}
