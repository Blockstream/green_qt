import Blockstream.Green
import Blockstream.Green.Core
import QtCore
import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

StackViewPage {
    required property AirgappedSignController controller
    required property Context context

    id: self
    title: 'Validate transaction'
    rightItem: CloseButton {
        onClicked: self.closeClicked()
    }
    contentItem: VFlickable {
        alignment: Qt.AlignTop
        spacing: 10
        ColumnLayout {
            Layout.alignment: Qt.AlignCenter
            Image {
                Layout.alignment: Qt.AlignCenter
                Layout.preferredHeight: 32
                Layout.preferredWidth: 32
                antialiasing: true
                fillMode: Image.PreserveAspectFit
                mipmap: true
                smooth: true
                source: 'qrc:/svg3/jade_qr_unlock_step_1.svg'
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                font.pixelSize: 12
                font.weight: 700
                horizontalAlignment: Label.AlignHCenter
                text: 'STEP 2'
                wrapMode: Label.WordWrap
            }
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            Layout.topMargin: 10
            font.pixelSize: 26
            font.weight: 600
            horizontalAlignment: Label.AlignHCenter
            text: qsTrId('id_scan_qr_on_jade')
            wrapMode: Label.WordWrap
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            Layout.maximumWidth: 420
            Layout.preferredWidth: 0
            font.pixelSize: 14
            font.weight: 400
            horizontalAlignment: Label.AlignHCenter
            opacity: 0.6
            text: 'Validate the transaction details on Jade'
            wrapMode: Label.WordWrap
        }
        ScannerView {
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 10
            Layout.minimumWidth: 320
            Layout.minimumHeight: 320
            context: self.context
            enabled: self.controller.monitor?.idle ?? true
            onBcurScanned: (result) => {
                if (result.ur_type === 'crypto-psbt') {
                    self.controller.importSignedPsbt(result.psbt)
                }
            }
        }
        VSpacer {
        }
    }
    Connections {
        target: self.controller
        function onFailed(error) {
            self.pushPage(error_page, { error })
        }
    }
    Component {
        id: error_page
        ErrorPage {
        }
    }
    footerItem: RegularButton {
        Layout.fillWidth: true
        cyan: true
        text: qsTrId('id_import_from_file')
        onClicked: file_dialog.open()
    }
    FileDialog {
        id: file_dialog
        currentFolder: StandardPaths.standardLocations(StandardPaths.DocumentsLocation)[0]
        onAccepted: {
            const psbt = self.controller.parsePsbtFile(file_dialog.selectedFile)
            if (psbt.length === 0) {
                self.pushPage(error_page, {
                    error: qsTr('The selected file does not contain a valid PSBT.'),
                })
                return
            }
            self.controller.importSignedPsbt(psbt)
        }
    }
}
