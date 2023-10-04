import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    signal loadFinished(Context context)
    required property Context context
    StackView.onActivated: controller.load()
    id: self
    title: self.context.wallet.name
    padding: 60
    LoadController {
        id: controller
        context: self.context
        onLoadFinished: {
            self.loadFinished(self.context)
        }
    }
    background: Item {
        Image {
            anchors.fill: parent
            anchors.margins: -constants.p3
            source: 'qrc:/svg2/onboard_background.svg'
            fillMode: Image.PreserveAspectCrop
        }
    }
    contentItem: ColumnLayout {
        VSpacer {
        }
        BusyIndicator {
            Layout.alignment: Qt.AlignCenter
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            font.family: 'SF Compact Display'
            font.pixelSize: 26
            font.weight: 600
            horizontalAlignment: Label.AlignHCenter
            text: qsTrId('id_loading_wallet')
            wrapMode: Label.WordWrap
        }
        VSpacer {
        }
    }
}
