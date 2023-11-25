import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

ItemDelegate {
    required property var address

    id: self
    hoverEnabled: true
    padding: constants.p3
    verticalPadding: constants.p1

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
