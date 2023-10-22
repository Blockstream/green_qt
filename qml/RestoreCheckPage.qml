import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    signal restoreFinished(Context context)
    required property var mnemonic
    required property string password
    RestoreController {
        id: controller
        mnemonic: self.mnemonic
        password: self.password
//        onErrorsChanged: {
//            if (errors.mnemonic === 'invalid') {
//                self.failedRecoveryPhraseCheck()
//            }
//        }
        // onFailedRecoveryPhraseCheck: {
        //     Analytics.recordEvent('failed_recovery_phrase_check', {
        //         network: navigation.param.network === 'bitcoin' ? 'mainnet' : navigation.param.network
        //     })
        // }
        onRestoreFinished: (context) => self.restoreFinished(context)
    }
    StackView.onActivated: controller.restore()
    id: self
    padding: 60
    background: Item {
        Image {
            anchors.fill: parent
            anchors.margins: -constants.p3
            source: 'qrc:/svg2/onboard_background.svg'
            fillMode: Image.PreserveAspectCrop
        }
    }
    contentItem: ColumnLayout {
        BusyIndicator {
            Layout.alignment: Qt.AlignCenter
            running: true
        }
    }
}
