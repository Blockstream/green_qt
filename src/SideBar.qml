import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.12
import './views'

Page {
    background: Rectangle {
        color: 'black'
        opacity: 0.2
    }

    header: ColumnLayout {
        Image {
            Layout.alignment: Qt.AlignRight
            Layout.margins: 8

            source: 'assets/assets/svg/logo_big.svg'
            sourceSize.height: 32
            smooth: false
            mipmap: true

            MouseArea {
                anchors.fill: parent
                onClicked: drawer.open()
            }
        }

        TextField {
            Layout.margins: 8
            placeholderText: qsTr('SEARCH')
            enabled: false
            Layout.fillWidth: true
        }
    }

    ScrollView {
        id: scroll_view
        clip: true
        anchors.fill: parent
        anchors.leftMargin: 8

        Column {
            spacing: 16

            WalletsSidebarItem {
                width: scroll_view.width
            }

            DevicesSidebarItem {
                width: scroll_view.width
            }
        }
    }
/*
            RowLayout {
                Layout.leftMargin: 8
                Label {
                    Layout.fillWidth: true
                    //font.pixelSize: 12
                    opacity: 0.5
                    text: qsTr('WALLETS')
                }
                ToolButton {
                    visible: false
                    icon.source: 'assets/assets/svg/advanced.svg'
                    icon.width: 16
                    icon.height: 16
                    action: restore_wallet_action
                }
            }
*/

/*


                //currentIndex: -1

                onCurrentItemChanged: {
                    if (currentItem) stack_view.push(device_view_component, { device: currentItem.device });
                    else stack_view.pop()
                }

                delegate: Pane {
                    property Device device: modelData

                    property bool isCurrent: ListView.isCurrentItem
                    width: parent.width
                    background: MouseArea {
                        hoverEnabled: true
                        //onClicked: list_view.currentIndex = index

                        Rectangle {
                            anchors.fill: parent
                            anchors.leftMargin: -8
                            anchors.rightMargin: -4
                            color: 'white'
                            opacity: isCurrent ? 0.1 : (parent.containsMouse ? 0.05 : 0)
                        }
                        ProgressBar {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            indeterminate: true
                            visible: !device.properties.connected || !device.properties.app
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        Image {
                            sourceSize.width: 24
                            sourceSize.height: 24
                            source: 'assets/assets/svg/ledger.svg'
                        }

                        Label {
                            Layout.fillWidth: true
                            text: 'LEDGER NANO X' //modelData.name
                        }
                        Image {
                            sourceSize.width: 16
                            sourceSize.height: 16
                            source: 'assets/assets/svg/arrow_right.svg'
                        }
                        ToolButton {
                            visible: false
                            icon.source: 'assets/assets/svg/arrow_right.svg'
                            icon.width: 16
                            icon.height: 16
    //                        onClicked: { stack_view.push(wallet_foo, { wallet: modelData }); list_view.currentIndex = index }
                            enabled: !isCurrent
                        }
                    }
                }
            }        }
    }
*/

}
