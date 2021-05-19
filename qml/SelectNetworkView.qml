import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.15
import QtQml 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQml.Models 2.0

GPane {
    required property bool showAMP
    required property string view

    id: self
    background: null
    contentItem: RowLayout {
        HSpacer {
        }
        Section {
            visible: navigation.path === `/${view}` || navigation.path === `/mainnet/${view}`
            title: 'Bitcoin Network'
            color: 'orange'
            contentItem: RowLayout {
                spacing: 24
                Card {
                    network: 'mainnet'
                    type: 'default'
                    icons: [window.icons['mainnet']]
                    title: 'Bitcoin Wallet'
                    description: qsTrId('id_bitcoin_is_the_worlds_leading')
                }
                HSpacer {
                }
            }
        }
        Section {
            visible: navigation.path === `/${view}` || navigation.path === `/liquid/${view}`
            title: 'Liquid Network'
            color: 'cyan'
            contentItem: RowLayout {
                spacing: 24
                Card {
                    network: 'liquid'
                    type: 'default'
                    icons: [window.icons['liquid']]
                    title: 'Liquid Wallet'
                    description: qsTrId('id_the_liquid_network_is_a_bitcoin')
                }
                Card {
                    visible: self.showAMP
                    network: 'liquid'
                    type: 'amp'
                    icons: ['qrc:/svg/amp.svg']
                    title: 'AMP Wallet'
                    description: qsTrId('AMP accounts are only available on Liquid wallets. You may be required to provide your account ID to issuers to receive an AMP Asset.')
                }
                HSpacer {
                }
            }
        }
        HSpacer {
        }
    }

    component Card: Button {
        id: self
        required property string network
        required property string type
        required property string title
        property string description
        property var icons
        Layout.minimumHeight: 160
        Layout.preferredWidth: 280
        Layout.maximumWidth: 280
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
                        source: modelData
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                    }
                }
                Label {
                    Layout.fillWidth: true
                    text: self.title
                    font.bold: true
                    font.pixelSize: 24
                }
            }
            Label {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: self.description
                font.pixelSize: 14
                wrapMode: Label.WordWrap
                horizontalAlignment: Label.AlignJustify
            }
        }
        onClicked: navigation.set({ network: self.network, type: self.type })
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
