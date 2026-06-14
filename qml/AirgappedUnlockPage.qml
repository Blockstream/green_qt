import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Layouts

StackViewPage {
    required property AirgappedSignController controller
    required property Recipient recipient
    required property var rootPage

    signal exitSendFlow

    id: self
    title: 'Unlock Jade'
    rightItem: CloseButton {
        onClicked: self.exitToSendConfirm()
    }

    readonly property Context context: self.controller.context

    function exitToSendConfirm() {
        self.popPage(self.rootPage)
    }

    function exitSendDrawer() {
        self.exitSendFlow()
    }

    function pushExport() {
        if (self.controller.parts.length === 0 && (self.controller.monitor?.idle ?? true))
            self.controller.exportPsbt()
        self.pushPage(airgap_export_page, {
            controller: self.controller,
            recipient: self.recipient,
            account: self.controller.account,
            transaction: self.controller.transaction,
        })
    }

    function pushQrUnlock() {
        self.pushPage(qr_unlock_page, {
            context: self.context,
        })
    }

    function pushImport() {
        self.pushPage(airgap_import_page, {
            controller: self.controller,
            context: self.context,
        })
    }

    contentItem: VFlickable {
        alignment: Qt.AlignTop
        JadeUnlockSignView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            onAlreadyUnlocked: self.pushExport()
            onUnlockRequested: self.pushQrUnlock()
        }
    }
    Component {
        id: airgap_export_page
        AirgappedExportPage {
            onImportRequested: self.pushImport()
            onCloseClicked: self.exitSendDrawer()
        }
    }
    Component {
        id: airgap_import_page
        AirgappedImportPage {
            onCloseClicked: self.exitSendDrawer()
        }
    }
    Component {
        id: qr_unlock_page
        JadeQRUnlockPage {
            onExportRequested: self.pushExport()
            onCloseClicked: self.exitToSendConfirm()
        }
    }
}
