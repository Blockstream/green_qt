import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

StackViewPage {
    required property string error
    id: self
    contentItem: ColumnLayout {
        VSpacer {
        }
        CanceledImage {
            Layout.alignment: Qt.AlignCenter
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            Layout.topMargin: 10
            Layout.bottomMargin: 20
            horizontalAlignment: Label.AlignHCenter
            font.pixelSize: 14
            font.weight: 400
            text: UtilJS.formatError(self.error)
            wrapMode: Label.Wrap
        }
        PrimaryButton {
            Layout.alignment: Qt.AlignCenter
            Layout.minimumWidth: 200
            focus: true
            text: qsTrId('id_ok')
            onClicked: self.popPage()
            visible: (self.StackView.view?.depth ?? 0) > 1
        }
        VSpacer {
        }
    }
}
