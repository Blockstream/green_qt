import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    StackView.onActivated: controller.restore()
    required property var mnemonic
    required property string password
    id: self
    padding: 60
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
        Label {
            text: mnemonic.join(' - ')
        }
        Label {
            text: password
        }
        TaskDispatcherInspector {
            Layout.fillHeight: true
            Layout.fillWidth: true
            dispatcher: controller.dispatcher
        }
    }
}
