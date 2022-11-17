import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.13
import QtQuick.Window 2.12

import "analytics.js" as AnalyticsJS

AbstractDialog {
    required property Wallet wallet
    property bool active: self.wallet.activities.length > 0 || (self.wallet.session && self.wallet.session.connecting)

    id: self
    icon: iconFor(self.wallet)
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
