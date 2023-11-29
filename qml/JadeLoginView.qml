import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    signal loginFinished(Context context)
    required property Context context
    StackView.onActivated: controller.loginWithDevice()
    id: self
    spacing: 20
    LoginController {
        id: controller
        context: self.context
        onLoginFinished: (context) => self.loginFinished(context)
    }
    VSpacer {
    }
    BusyIndicator {
        Layout.alignment: Qt.AlignCenter
    }
    Label {
        Layout.fillWidth: true
        Layout.preferredWidth: 0
        color: '#FFFFFF'
        font.pixelSize: 22
        font.weight: 600
        horizontalAlignment: Label.AlignHCenter
        text: qsTrId('id_logging_in')
        wrapMode: Label.WordWrap
    }
    VSpacer {
    }
}
