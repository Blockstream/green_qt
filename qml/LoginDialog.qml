import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Window

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

AbstractDialog {
    required property Wallet wallet
    property bool active: self.wallet.activities.length > 0 || (self.wallet.session && self.wallet.session.connecting)

    id: self
    icon: UtilJS.iconFor(self.wallet)
    focus: true
    title: self.wallet.name

    closePolicy: self.active ? Dialog.NoAutoClose : AbstractDialog.closePolicy
    enableRejectButton: !self.active

    AnalyticsView {
        name: 'Login'
        active: self.opened
        segmentation: AnalyticsJS.segmentationSession(self.wallet)
    }

    contentItem: StackView {
        id: stack_view
        implicitHeight: currentItem.implicitHeight
        implicitWidth: currentItem.implicitWidth
        onCurrentItemChanged: currentItem.forceActiveFocus()
        initialItem: self.wallet.watchOnly ? login_with_password_view : login_with_pin_view
    }

    Component {
        id: login_with_password_view
        LoginWithPasswordView {
            wallet: self.wallet
        }
    }

    Component {
        id: login_with_pin_view
        LoginWithPinView {
            wallet: self.wallet
        }
    }

    footer: DialogFooter {
        SessionBadge {
            visible: self.wallet.loginAttemptsRemaining > 0
            session: self.wallet.session
        }
        HSpacer {}
    }
}
