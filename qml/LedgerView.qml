import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.12

MainPage {
    id: self
    readonly property bool busy: {
        return false
    }
    readonly property int count: 0
    DeviceDiscoveryAgent {
    }
    header: MainPageHeader {
        padding: 16
        background: Item { }
        contentItem: RowLayout {
            spacing: 16
            Image {
                source: 'qrc:/svg/ledger-logo.svg'
                sourceSize.height: 32
            }
            Label {
                text: 'Ledger Devices'
                font.pixelSize: 24
                font.family: 'Roboto'
                font.styleName: 'Thin'
            }
            Item {
                Layout.fillWidth: true
                height: 1
            }
            Button {
                text: 'Store'
                highlighted: true
                onClicked: Qt.openUrlExternally('https://store.blockstream.com/product-category/physical_storage/')
            }
        }
    }
    contentItem: StackLayout {
        currentIndex: self.count === 0 ? 0 : 1
        ColumnLayout {
            spacing: 16
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
            Flipable {
                id: flipable
                property bool flipped: false
                width: Math.max(nano_s_image.width, nano_x_image.width)
                height: Math.max(nano_s_image.height, nano_x_image.height)
                Layout.alignment: Qt.AlignHCenter
                front: Image {
                    id: nano_x_image
                    anchors.centerIn: parent
                    source: 'qrc:/svg/ledger_nano_x.svg'
                }
                back: Image {
                    id: nano_s_image
                    anchors.centerIn: parent
                    source: 'qrc:/svg/ledger_nano_s.svg'
                }
                transform: Rotation {
                    id: rotation
                    origin.x: flipable.width / 2
                    origin.y: flipable.height / 2
                    axis.x: 1
                    axis.y: 0
                    axis.z: 0
                    angle: flipable.flipped ? 180 : 0
                    Behavior on angle {
                        SmoothedAnimation { }
                    }
                }
                Timer {
                    repeat: true
                    running: true
                    interval: 3000
                    onTriggered: flipable.flipped = !flipable.flipped
                }
            }

            Pane {
                Layout.topMargin: 40
                Layout.alignment: Qt.AlignHCenter
                background: Rectangle {
                    radius: 8
                    border.width: 2
                    border.color: constants.c600
                    color: "transparent"
                }
                contentItem: RowLayout {
                    spacing: 16
                    Image {
                        Layout.alignment: Qt.AlignVCenter
                        sourceSize.width: 32
                        sourceSize.height: 32
                        fillMode: Image.PreserveAspectFit
                        source: 'qrc:/svg/usbAlt.svg'
                        clip: true
                    }
                    Label {
                        Layout.alignment: Qt.AlignVCenter
                        text: `Connect your Ledger Nano ${flipable.flipped ? 'S' : 'X'} to use it with Green`
                    }
                }
            }
            Label {
                Layout.alignment: Qt.AlignHCenter
                wrapMode: Text.WordWrap
                text: `<a href="${url}">Learn more about Blockstream Jade in our help center</a>`
                textFormat: Text.RichText
                color: 'white'
                onLinkActivated: Qt.openUrlExternally(url)
            }
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
        ColumnLayout {
            spacing: 16
            Item {
                Layout.fillHeight: true
                width: 1
            }
        }
    }
}
