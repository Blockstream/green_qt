import Blockstream.Green
import QtQuick

AbstractDrawer {
    required property JadeDevice device
    onClosed: self.destroy()
    id: self
    edge: Qt.RightEdge
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
