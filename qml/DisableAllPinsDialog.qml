import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

WalletDialog {
    onClosed: self.destroy()

    id: self
    clip: true
    header: null
    title: qsTrId('id_disable_pin_access')
    Overlay.modal: Rectangle {
        anchors.fill: parent
        color: 'black'
        opacity: 0.6
    }
    Controller {
        id: controller
        context: self.context
        onFinished: self.close()
    }
    TaskPageFactory {
        title: self.title
        monitor: controller.monitor
        target: stack_view
    }
    contentItem: GStackView {
        id: stack_view
        implicitWidth: Math.max(500, stack_view.currentItem.implicitWidth)
        implicitHeight: Math.max(0, stack_view.currentItem.implicitHeight)
        initialItem: StackViewPage {
            title: self.title
            rightItem: CloseButton {
                onClicked: self.close()
            }
            contentItem: ColumnLayout {
                VSpacer {
                }
                Label {
                    Layout.alignment: Qt.AlignCenter
                    Layout.fillWidth: true
                    Layout.maximumWidth: 360
                    text: qsTrId('id_this_will_disable_pin_login_for')
                    horizontalAlignment: Label.AlignHCenter
                    wrapMode: Text.WordWrap
                }
                RowLayout {
                    Layout.fillWidth: false
                    Layout.alignment: Qt.AlignCenter
                    CheckBox {
                        id: confirm_checkbox
                    }
                    Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: qsTrId('id_i_confirm_i_want_to_disable_pin')
                    }
                }
                PrimaryButton {
                    Layout.alignment: Qt.AlignCenter
                    text: qsTrId('id_disable_pin_access')
                    enabled: confirm_checkbox.checked
                    onClicked: controller.disableAllPins()
                }
                VSpacer {
                }
            }
        }
    }
}
