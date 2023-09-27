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
    title: self.wallet.name

    controller: loader.item.controller

    Connections {
        target: self.controller
        function onLoginFinished() {
            self.accept()
        }
    }

    AnalyticsView {
        name: 'Login'
        active: self.opened
        segmentation: AnalyticsJS.segmentationSession(self.wallet)
    }

    Loader {
        id: loader
        sourceComponent: self.wallet.watchOnly ? login_with_password_view : login_with_pin_view
        focus: true
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
