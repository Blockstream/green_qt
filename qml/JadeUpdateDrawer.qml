import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls

AbstractDrawer {
    property JadeDevice device: null
    // Without a device, one is picked and unlocked on this context.
    property Context context: null
    onClosed: self.destroy()
    id: self
    edge: Qt.RightEdge
    contentItem: GStackView {
        id: stack_view
        initialItem: self.device ? update_view : connect_page
    }
    Component {
        id: connect_page
        ConnectJadePage {
            context: self.context
            wallet: self.context?.wallet ?? null
            onDeviceSelected: (device) => {
                self.device = device
                stack_view.replace(null, update_view, StackView.PushTransition)
            }
            onCloseClicked: self.close()
        }
    }
    Component {
        id: update_view
        JadeAdvancedUpdateView {
            device: self.device
            showSkip: false
            onCloseClicked: self.close()
            onFirmwareSelected: (firmware) => stack_view.push(confirm_update_view, { firmware })
        }
    }
    Component {
        id: confirm_update_view
        JadeConfirmUpdatePage {
            device: self.device
            onCloseClicked: self.close()
            onUpdateFailed: stack_view.pop()
            onUpdateFinished: stack_view.replace(firmware_updated_page)
        }
    }
    Component {
        id: firmware_updated_page
        JadeFirmwareUpdatedPage {
            leftItem: null
            rightItem: CloseButton {
                onClicked: self.close()
            }
            onTimeout: self.close()
        }
    }
}
