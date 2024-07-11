import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

WalletDrawer {
    required property Account account
    required property var unspents
    required property string status
    id: self
    contentItem: GStackView {
        initialItem: UpdateUnspentsPage {
            context: self.context
            account: self.account
            unspents: self.unspents
            status: self.status
            onClosed: self.close()
        }
    }

    component UpdateUnspentsPage: StackViewPage {
        signal closed()
        required property Context context
        required property Account account
        required property var unspents
        required property string status
        id: self
        title: self.status === 'default' ? qsTrId('id_unlocking_coins') : qsTrId('id_locking_coins')
        TaskPageFactory {
            title: self.title
            monitor: controller.monitor
            target: self.StackView.view
            onClosed: self.closed()
        }
        SessionController {
            id: controller
            context: self.context
            session: self.account.session
            onFinished: {
                self.closed()
            }
        }
        rightItem: CloseButton {
            onClicked: self.closed()
        }
        footerItem: PrimaryButton {
            text: qsTrId('id_continue')
            onClicked: controller.setUnspentOutputsStatus(self.account, self.unspents, self.status)
        }
        contentItem: Flickable {
            ScrollIndicator.vertical: ScrollIndicator {
            }
            id: flickable
            clip: true
            contentWidth: flickable.width
            contentHeight: layout.height
            ColumnLayout {
                id: layout
                width: flickable.width
                spacing: 5
                Label {
                    Layout.bottomMargin: 20
                    Layout.preferredWidth: 0
                    Layout.fillWidth: true
                    text: {
                        if (status === 'default') {
                            return qsTrId('id_unlocked_coins_can_be_spent_and')
                        }
                        if (status === 'frozen') {
                            return qsTrId('id_locked_coins_will_not_be_spent')
                        }
                    }
                    wrapMode: Label.WrapAnywhere
                }
                Repeater {
                    model: self.unspents
                    delegate: OutputDelegate {
                        required property var modelData
                        Layout.fillWidth: true
                        output: modelData
                        background: Rectangle {
                            color: '#222226'
                            radius: 5
                        }
                    }
                }
            }
        }
    }
}
