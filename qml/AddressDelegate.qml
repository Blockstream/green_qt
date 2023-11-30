import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

ItemDelegate {
    signal signMessage(Address address)
    required property Address address

    id: self
    hoverEnabled: true
    padding: constants.p3
    verticalPadding: constants.p1

    background: Item {
        Rectangle {
            anchors.fill: parent
            visible: self.hovered
            color: '#00B45A'
            opacity: 0.08
        }
        Rectangle {
            color: '#FFFFFF'
            opacity: 0.1
            width: parent.width
            height: 1
            y: parent.height - 1
        }
    }
    contentItem: RowLayout {
        ColumnLayout {
            Layout.fillWidth: false
            Layout.rightMargin: constants.p2
            spacing: 8
            Label {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                padding: 8
                topPadding: 2
                bottomPadding: 2
                background: Rectangle {
                    color: "white"
                    radius: 4
                }
                text: address.data["tx_count"]
                color: "black"
                horizontalAlignment: Label.AlignHCenter
                font.pixelSize: 12
                font.capitalization: Font.AllUppercase
                font.styleName: 'Medium'
            }
            Label {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                text: "TX COUNT"
                color: "white"
                font.pixelSize: 10
                font.weight: 400
                font.styleName: 'Regular'
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: constants.p1
            Label {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: address.data["address"]
                font.pixelSize: 12
                font.styleName: 'Regular'
            }
            RowLayout {
                Tag {
                    color: constants.c500
                    text: localizedLabel(address.data["address_type"])
                    font.capitalization: Font.AllUppercase
                }
            }
        }

        Image {
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
            source: 'qrc:/svg/copy.svg'
            opacity: self.hovered ? 1 : 0
            Behavior on opacity {
                OpacityAnimator {
                }
            }
        }
    }
    onClicked: {
        Clipboard.copy(address.data["address"]);
        ToolTip.show(qsTrId('id_copied_to_clipboard'), 1000);
    }
}
