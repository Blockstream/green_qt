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
    padding: 60
    title: self.context.wallet.name
    LoadController {
        id: controller
        context: self.context
        onLoadFinished: self.loadFinished(self.context)
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
            font.pixelSize: 22
            font.weight: 600
            horizontalAlignment: Label.AlignHCenter
            text: qsTrId('id_loading_wallet')
            wrapMode: Label.WordWrap
        }
        VSpacer {
        }
    }
}
