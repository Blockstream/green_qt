import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

MainPage {
    required property Wallet wallet

    id: self

    Component.onCompleted: {
        if (self.wallet?.context) {
            stack_view.push(loading_page, { context: self.wallet.context }, StackView.Immediate)
        }
    }

    contentItem: GStackView {
        id: stack_view
        focus: true
        initialItem: pin_login_page
        onCurrentItemChanged: stack_view.currentItem.forceActiveFocus()
    }

    Component {
        id: pin_login_page
        PinLoginPage {
            wallet: self.wallet
            onLoginFinished: (context) => {
                stack_view.push(loading_page, { context })
            }
        }
    }

    Component {
        id: loading_page
        LoadingPage {
            onLoadFinished: (context) => {
                stack_view.push(overview_page, { context })
            }
        }
    }

    Component {
        id: overview_page
        OverviewPage {
        }
    }
}
