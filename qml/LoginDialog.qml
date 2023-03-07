import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Window

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

ControllerDialog {
    id: self
    icon: UtilJS.iconFor(self.wallet)
    title: self.wallet.name

    closePolicy: self.active ? Dialog.NoAutoClose : AbstractDialog.closePolicy
    // enableRejectButton: !self.active

    controller: loader.item.controller

    AnalyticsView {
        name: 'Login'
        active: self.opened
        segmentation: AnalyticsJS.segmentationSession(self.wallet)
    }

    Loader {
        id: loader
        sourceComponent: self.wallet.watchOnly ? login_with_password_view : login_with_pin_view
        focus: StackLayout.isCurrentItem
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
}
