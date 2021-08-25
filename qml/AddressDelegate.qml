import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

Button {
    required property var address

    id: self
    hoverEnabled: true
    padding: constants.p3
    background: Rectangle {
        color: self.hovered ? constants.c700 : constants.c800
        radius: 4
        border.width: self.highlighted ? 1 : 0
        border.color: constants.g500
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
                font.pixelSize: 8
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
                    text: address.data["address_type"]
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
