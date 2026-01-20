import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

WalletDialog {
    required property JadeDevice device
    id: self
    objectName: "JadeUpdateDialog2"
    clip: true
    width: 650
    height: 700
    contentItem: GStackView {
        id: stack_view
        initialItem: JadeAdvancedUpdateView {
            device: self.device
            showSkip: false
            onFirmwareSelected: (firmware) => stack_view.push(confirm_update_view, { firmware })
        }
    }
    Component {
        id: confirm_update_view
        JadeConfirmUpdatePage {
            id: view
            device: self.device
            onUpdateFailed: stack_view.pop()
            onUpdateFinished: stack_view.replace(firmware_updated_page)
        }
    }
    Component {
        id: firmware_updated_page
        JadeFirmwareUpdatedPage {
            header: null
            onTimeout: self.close()
        }
    }
}
