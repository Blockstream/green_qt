import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    signal restoreFinished(Context context)
    signal alreadyRestored(Wallet wallet)
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
        onAlreadyRestored: (wallet) => self.alreadyRestored(wallet)
    }
    StackView.onActivated: controller.restore()
    id: self
    leftItem: Item {
    }
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
        VSpacer {
        }
        BusyIndicator {
            Layout.alignment: Qt.AlignCenter
            running: true
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            font.family: 'SF Compact Display'
            font.pixelSize: 26
            font.weight: 600
            horizontalAlignment: Label.AlignHCenter
            text: qsTrId('id_restoring_your_wallet')
            wrapMode: Label.WordWrap
        }
        VSpacer {
        }
    }
}
