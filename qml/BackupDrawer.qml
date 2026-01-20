import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

WalletDrawer {
    id: self
    objectName: "BackupDrawer"
    contentItem: GStackView {
        id: stack_view
        initialItem: BackupPage {
            context: self.context
            onCloseClicked: self.close()
            onCompleted: self.close()
        }
    }
}
