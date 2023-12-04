import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

WalletDrawer {
    signal created(Account account)
    required property Asset asset
    property bool dismissable: true
    id: self
    preferredContentWidth: stack_view.currentItem.implicitWidth

    closePolicy: self.dismissable ? Popup.CloseOnEscape | Popup.CloseOnPressOutside : Popup.NoAutoClose
    interactive: self.dismissable
    contentItem: GStackView {
        id: stack_view
        focus: true
        initialItem: CreateAccountPage {
            context: self.context
            asset: self.asset
            editableAsset: true
            rightItem: CloseButton {
                visible: self.dismissable
                onClicked: self.close()
            }
            onCreated: (account) => {
                self.created(account)
                self.close()
            }
        }
    }
}
