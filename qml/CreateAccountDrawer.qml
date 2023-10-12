import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

WalletDrawer {
    signal created(Account account)
    required property Asset asset
    id: self
    width: 450

    contentItem: GStackView {
        id: stack_view
        focus: true
        initialItem: CreateAccountPage {
            context: self.context
            asset: self.asset
            editableAsset: true
            rightItem: CloseButton {
                onClicked: self.close()
            }
            onCreated: (account) => self.created(account)
        }
    }
}
