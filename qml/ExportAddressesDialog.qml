import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

WalletDialog {
    required property Account account
    id: self
    title: 'Export Addresses to CSV File'
    header: null
    closePolicy: WalletDialog.NoAutoClose
    topPadding: 20
    bottomPadding: 20
    leftPadding: 20
    rightPadding: 20
    width: 400
    height: 400
    onClosed: self.destroy()
    onOpened: controller.save()
    ExportAddressesController {
        id: controller
        context: self.context
        account: self.account
        onRejected: self.reject()
        onSaved: (name, url) => {
            self.closePolicy = Popup.CloseOnEscape | Popup.CloseOnPressOutside
            stack_view.replace(null, finished_page, { name, url }, StackView.PushTransition)
        }
    }
    contentItem: GStackView {
        id: stack_view
        initialItem: StackViewPage {
            title: self.title
            contentItem: ColumnLayout {
                BusyIndicator {
                    Layout.alignment: Qt.AlignCenter
                }
            }
        }
    }

    Component {
        id: finished_page
        StackViewPage {
            required property string name
            required property url url
            id: page
            title: self.title
            rightItem: CloseButton {
                onClicked: self.accept()
            }
            contentItem: ColumnLayout {
                VSpacer {
                }
                CompletedImage {
                    Layout.alignment: Qt.AlignCenter
                }
                PreferencesView.FileButton {
                    Layout.alignment: Qt.AlignCenter
                    text: page.name
                    url: page.url
                }
                VSpacer {
                }
            }
        }
    }
}
