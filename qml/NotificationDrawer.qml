import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import QtQml

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

AbstractDrawer {
    required property Notification notification
    onClosed: drawer.destroy()

    id: drawer
    objectName: "NotificationDrawer"
    edge: Qt.RightEdge
    minimumContentWidth: 450
    contentItem: GStackView {
        id: stack_view
        initialItem: {
            if (drawer.notification instanceof OutageNotification) {
                return outage_page
            } else if (drawer.notification instanceof TwoFactorExpiredNotification) {
                return two_factor_expired_page
            } else if (drawer.notification instanceof BackupNotification) {
                return backup_page
            } else {
                console.log('unhandled notification trigger', notification)
            }
        }
    }
    Component {
        id: outage_page
        OutagePage {
            context: self.context
            onLoadFinished: drawer.close()
        }
    }
    Component {
        id: two_factor_expired_page
        TwoFactorExpiredSelectAccountPage {
            context: self.context
            notification: drawer.notification
            rightItem: CloseButton {
                onClicked: drawer.close()
            }
            onCloseClicked: drawer.close()
        }
    }

    Component {
        id: backup_page
        BackupPage {
            context: (drawer.notification as BackupNotification).context
            onCloseClicked: drawer.close()
            onCompleted: drawer.close()
        }
    }
}
