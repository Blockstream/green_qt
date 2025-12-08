import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    required property Transaction transaction
    id: self
    leftItem: Item {
    }
    rightItem: CloseButton {
        onClicked: self.closeClicked()
    }
    contentItem: ColumnLayout {
        spacing: 10
        VSpacer {
        }
        CompletedImage {
            Layout.alignment: Qt.AlignCenter
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.bottomMargin: 20
            font.pixelSize: 20
            font.weight: 700
            text: qsTrId('id_transaction_sent')
        }
        Label {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            font.pixelSize: 14
            font.weight: 400
            text: self.transaction.data.txhash
            horizontalAlignment: Label.AlignHCenter
            wrapMode: Label.Wrap
        }
        Pane {
            id: tools_pane
            Layout.topMargin: 10
            Layout.alignment: Qt.AlignCenter
            padding: 12
            background: Rectangle {
                border.width: 1
                border.color: '#FFF'
                color: 'transparent'
                radius: height / 2
                opacity: tools_pane.hovered ? 0.4 : 0
                Behavior on opacity {
                    SmoothedAnimation {
                        velocity: 2
                    }
                }
            }
            contentItem: RowLayout {
                spacing: 20
                ShareButton {
                    url: self.transaction.url
                }
                CircleButton {
                    icon.source: 'qrc:/svg2/copy.svg'
                    onClicked: Clipboard.copy(self.transaction.data.txhash)
                }
            }
        }
        VSpacer {
        }
    }
}
