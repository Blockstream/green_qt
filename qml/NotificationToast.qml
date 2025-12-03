import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

import "util.js" as UtilJS

ColumnLayout {
    required property var notifications
    
    property var animatedSet: new Set()
    
    readonly property var items: {
        const items = []
        for (let i = 0; i < self.notifications.length; i++) {
            const notification = self.notifications[i]
            let delegate
            if (notification instanceof UpdateNotification) {
                delegate = update_toast
            } else if (notification instanceof OutageNotification) {
                delegate = outage_toast
            } else if (notification instanceof WarningNotification) {
                delegate = warning_toast
            } else if (notification instanceof TwoFactorResetNotification) {
                delegate = two_factor_reset_toast
            } else if (notification instanceof TwoFactorExpiredNotification) {
                delegate = two_factor_expired_toast
            } else if (notification instanceof SystemNotification) {
                delegate = system_message_toast
            } else if (notification instanceof AnalyticsAlertNotification) {
                delegate = analytics_alert_toast
            }
            if (delegate) {
                items.push({ delegate, notification })
            }
        }
        return items.reverse()
    }
    
    onNotificationsChanged: {
        if (self.notifications.length > 0) {
            const newestNotification = self.notifications[self.notifications.length - 1]
            if (!self.animatedSet.has(newestNotification) && newestNotification._animatedIn !== true) {
                newestNotification._isNew = true
                self.animatedSet.add(newestNotification)
            }
        }
    }

    id: self
    visible: self.items.length > 0
    spacing: 12
    height: implicitHeight
    
    Repeater {
        model: self.items
        delegate: Loader {
            readonly property Notification _notification: loader.modelData.notification
            required property var modelData
            id: loader
            sourceComponent: loader.modelData.delegate
            Layout.fillWidth: true
            Layout.preferredHeight: item && item.height === 0 ? 0 : implicitHeight
        }
    }

    // Toast components
    Component {
        id: system_message_toast
        SystemMessageToast {
        }
    }
    
    Component {
        id: outage_toast
        OutageToast {
        }
    }

    Component {
        id: warning_toast
        WarningToast {
        }
    }
    
    Component {
        id: two_factor_reset_toast
        TwoFactorResetToast {
        }
    }
    
    Component {
        id: two_factor_expired_toast
        TwoFactorExpiredToast {
        }
    }
    
    Component {
        id: analytics_alert_toast
        AnalyticsAlertToast {
        }
    }
    
    Component {
        id: update_toast
        UpdateToast {
        }
    }

    // Base toast component
    component Toast: Pane {
        required property color backgroundColor
        required property color textColor
        property Notification notification: _notification
        property color borderColor: backgroundColor
        
        id: toast
        padding: 20
        
        background: Rectangle {
            color: toast.backgroundColor
            radius: 8
            border.width: 1
            border.color: toast.borderColor
        }
        
        property bool isAnimatingIn: false
        property bool isAnimatingOut: false
        property bool shouldBeVisible: true
        property bool isDismissed: false
        property var creationTime: Date.now()
        property bool hasAnimatedIn: false
        
        x: implicitWidth
        opacity: 0
        
        Behavior on x {
            enabled: toast.isAnimatingIn || toast.isAnimatingOut
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
            }
        }
        Behavior on opacity {
            enabled: toast.isAnimatingIn || toast.isAnimatingOut
            NumberAnimation {
                duration: 300
            }
        }
        
        Behavior on height {
            enabled: toast.isAnimatingOut
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
            }
        }
        
        Component.onCompleted: {
            if (toast.notification.dismissed) {
                toast.opacity = 0
                toast.height = 0
                return
            }

            const isNew = toast.notification._isNew === true && toast.notification._animatedIn !== true
            if (isNew) {
                toast.isAnimatingIn = true
                toast.x = 0
                toast.opacity = 1
                Qt.callLater(() => { toast.isAnimatingIn = false })
                toast.hasAnimatedIn = true
                toast.notification._animatedIn = true
                delete toast.notification._isNew
            } else {
                toast.isAnimatingIn = false
                toast.x = 0
                toast.opacity = 1
                toast.hasAnimatedIn = true
            }

        }

        Timer {
            id: finishSlideOutTimer
            repeat: false
            interval: 320
            onTriggered: {
                toast.isAnimatingOut = false
                toast.height = 0
                if (!toast.notification.dismissed) {
                    toast.notification.dismiss()
                }
            }
        }
        
        Connections {
            target: toast.notification
            function onDismissedChanged() {
                if (toast.hasAnimatedIn && toast.notification.dismissed && !toast.isAnimatingOut && !toast.isDismissed) {
                    toast.slideOutAndDismiss()
                }
            }
        }
        
        function slideOutAndDismiss() {
            if (toast.isAnimatingOut || toast.isDismissed) return
            
            toast.isAnimatingOut = true
            toast.isDismissed = true
            toast.x = toast.parent.width
            toast.opacity = 0
            finishSlideOutTimer.restart()
        }
        
        function dismissImmediately() {
            if (toast.isAnimatingOut) return
            
            console.log("Dismissing notification immediately")
            toast.height = 0
            toast.notification.dismiss()
        }
    }

    component WarningToast: Toast {
        id: toast
        borderColor: '#7E2A0D'
        backgroundColor: '#432004'
        textColor: '#FFFFFF'
        
        contentItem: RowLayout {
            spacing: 8
            Layout.alignment: Qt.AlignCenter
            Image {
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                source: 'qrc:/svg2/warning-light.svg'
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Label {
                    Layout.fillWidth: true
                    color: toast.textColor
                    font.pixelSize: 14
                    font.weight: 700
                    text: toast.notification.title
                    wrapMode: Label.NoWrap
                    elide: Label.ElideRight
                }
                Label {
                    Layout.fillWidth: true
                    color: toast.textColor
                    font.pixelSize: 13
                    font.weight: 400
                    text: toast.notification.message
                    wrapMode: Label.WordWrap
                }
                RowLayout {
                    Layout.topMargin: 6
                    spacing: 8
                    Layout.alignment: Qt.AlignHCenter
                    PrimaryButton {
                        borderColor: '#FFFFFF'
                        fillColor: '#FFFFFF'
                        textColor: '#000000'
                        font.pixelSize: 12
                        font.weight: 600
                        text: 'Backup now'
                        padding: 6
                        leftPadding: 10
                        rightPadding: 10
                        topPadding: 6
                        bottomPadding: 6
                        onClicked: toast.notification.trigger()
                    }
                    PrimaryButton {
                        borderColor: '#FFFFFF'
                        fillColor: 'transparent'
                        textColor: '#FFFFFF'
                        font.pixelSize: 12
                        font.weight: 600
                        text: 'Remind me later'
                        padding: 6
                        leftPadding: 10
                        rightPadding: 10
                        topPadding: 6
                        bottomPadding: 6
                        onClicked: toast.slideOutAndDismiss()
                    }
                }
            }
            CloseButton {
                Layout.alignment: Qt.AlignTop
                onClicked: toast.slideOutAndDismiss()
            }
        }
    }

    component SystemMessageToast: Toast {
        id: toast
        borderColor: '#00BCFF'
        backgroundColor: '#004A66'
        textColor: '#FFFFFF'
        
        contentItem: RowLayout {
            spacing: 8
            Layout.alignment: Qt.AlignCenter
            Image {
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                source: 'qrc:/svg2/info_white.svg'
            }
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                
                Label {
                    Layout.fillWidth: true
                    color: toast.textColor
                    font.pixelSize: 14
                    font.weight: 600
                    text: toast.notification.network.displayName
                    wrapMode: Label.Wrap
                }
                Label {
                    Layout.fillWidth: true
                    color: toast.textColor
                    font.pixelSize: 13
                    font.weight: 400
                    text: toast.notification.message
                    textFormat: Label.MarkdownText
                    wrapMode: Label.WordWrap
                    onLinkActivated: Qt.openUrlExternally(link)
                }
                RowLayout {
                    Layout.topMargin: 4
                    spacing: 4
                    CheckBox {
                        id: confirm_checkbox
                        Layout.alignment: Qt.AlignCenter
                        Material.theme: Material.Dark
                        visible: !toast.notification.accepted
                    }
                    Label {
                        Layout.fillWidth: true
                        Layout.rightMargin: 4
                        color: toast.textColor
                        font.pixelSize: 12
                        text: qsTrId('id_i_confirm_i_have_read_and')
                        wrapMode: Label.Wrap
                        visible: !toast.notification.accepted
                    }
                    PrimaryButton {
                        Layout.alignment: Qt.AlignRight
                        borderColor: '#FFFFFF'
                        fillColor: '#FFFFFF'
                        textColor: '#000000'
                        font.pixelSize: 12
                        font.weight: 600
                        enabled: confirm_checkbox.checked
                        font.capitalization: Font.Capitalize
                        text: qsTrId('id_accept').toLowerCase()
                        padding: 6
                        leftPadding: 10
                        rightPadding: 10
                        topPadding: 6
                        bottomPadding: 6
                        onClicked: {
                            toast.notification.trigger()
                        }
                        visible: !toast.notification.accepted
                    }
                }
            }
            
            CloseButton {
                Layout.alignment: Qt.AlignTop
                onClicked: toast.slideOutAndDismiss()
            }
        }
    }

    component OutageToast: Toast {
        id: toast
        borderColor: '#9A0000'
        backgroundColor: '#4D0000'
        textColor: '#FFFFFF'
        
        contentItem: RowLayout {
            spacing: 8
            Layout.alignment: Qt.AlignCenter
            Image {
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                source: 'qrc:/svg2/plugs_white'
            }
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                
                Label {
                    Layout.fillWidth: true
                    color: toast.textColor
                    font.pixelSize: 13
                    font.weight: 700
                    text: 'Some accounts can not be logged in due to network issues. Please try again later.'
                    wrapMode: Label.WordWrap
                }
                
                RowLayout {
                    Layout.topMargin: 4
                    spacing: 8
                    HSpacer {}
                    PrimaryButton {
                        borderColor: '#FFFFFF'
                        fillColor: '#FFFFFF'
                        font.pixelSize: 12
                        font.weight: 600
                        text: 'Try again'
                        textColor: '#000000'
                        padding: 6
                        leftPadding: 10
                        rightPadding: 10
                        topPadding: 6
                        bottomPadding: 6
                        onClicked: {
                            toast.notification.trigger()
                        }
                    }
                }
            }
            
            CloseButton {
                Layout.alignment: Qt.AlignTop
                onClicked: toast.slideOutAndDismiss()
            }
        }
    }

    component TwoFactorResetToast: Toast {
        readonly property Session session: toast.notification.context.getOrCreateSession(toast.notification.network)
        id: toast
        borderColor: '#222226'
        backgroundColor: '#0A0A0C'
        textColor: '#FFFFFF'
        
        contentItem: RowLayout {
            spacing: 8
            Layout.alignment: Qt.AlignCenter    
            Image {
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                source: UtilJS.iconFor(toast.notification.network)
            }
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                
                RowLayout {
                    spacing: 8
                    Label {
                        color: toast.textColor
                        font.pixelSize: 14
                        opacity: 0.6
                        text: toast.notification.network.displayName
                    }
                }
                
                Label {
                    Layout.fillWidth: true
                    color: toast.textColor
                    font.pixelSize: 13
                    font.weight: 700
                    text: qsTrId('id_twofactor_reset_in_progress')
                    wrapMode: Label.WordWrap
                }
                
                Label {
                    Layout.fillWidth: true
                    color: toast.textColor
                    opacity: 0.8
                    font.pixelSize: 12
                    text: {
                        if (toast.session.config.twofactor_reset?.is_active ?? false) {
                            return qsTrId('id_your_wallet_is_locked_for_a').arg(toast.session.config.twofactor_reset.days_remaining)
                        } else {
                            return ''
                        }
                    }
                    wrapMode: Label.WordWrap
                }
            }
            
            CloseButton {
                Layout.alignment: Qt.AlignTop
                onClicked: toast.slideOutAndDismiss()
            }
        }
    }

    component TwoFactorExpiredToast: Toast {
        id: toast
        borderColor: '#F7D000'
        backgroundColor: '#7A5F00'
        textColor: '#FFFFFF'
        
        contentItem: RowLayout {
            spacing: 8
            Layout.alignment: Qt.AlignCenter
            Image {
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                source: 'qrc:/svg2/expired_2fa_white.svg'
            }
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                
                Label {
                    Layout.fillWidth: true
                    color: toast.textColor
                    font.pixelSize: 13
                    font.weight: 700
                    text: 'Some coins are no longer 2FA protected (%1 accounts)'.arg(toast.notification.accounts.length)
                    wrapMode: Label.WordWrap
                }
                
                RowLayout {
                    Layout.topMargin: 4
                    spacing: 8
                    HSpacer {}
                    PrimaryButton {
                        borderColor: '#FFFFFF'
                        fillColor: '#FFFFFF'
                        font.pixelSize: 12
                        font.weight: 500
                        text: 'Re-enable 2FA'
                        textColor: '#000000'
                        padding: 6
                        leftPadding: 10
                        rightPadding: 10
                        topPadding: 6
                        bottomPadding: 6
                        onClicked: {
                            toast.notification.trigger()
                        }
                    }
                }
            }
            
            CloseButton {
                Layout.alignment: Qt.AlignTop
                onClicked: toast.slideOutAndDismiss()
            }
        }
    }

    component AnalyticsAlertToast: Toast {
        id: toast
        borderColor: '#222226'
        backgroundColor: '#0A0A0C'
        textColor: '#FFFFFF'
        
        contentItem: ColumnLayout {
            spacing: 6
            Layout.alignment: Qt.AlignCenter
            RowLayout {
                spacing: 8
                Image {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    source: 'qrc:/svg2/warning_black.svg'
                }
                Label {
                    Layout.fillWidth: true
                    color: toast.textColor
                    font.pixelSize: 14
                    font.weight: 600
                    text: toast.notification.alert.title
                    wrapMode: Label.Wrap
                }
                CloseButton {
                    Layout.alignment: Qt.AlignTop
                    visible: toast.notification.dismissable
                    onClicked: toast.slideOutAndDismiss()
                }
            }
            
            Label {
                Layout.fillWidth: true
                color: toast.textColor
                font.pixelSize: 13
                font.weight: 400
                text: toast.notification.alert.message
                textFormat: Label.RichText
                wrapMode: Label.WordWrap
            }
            
            LinkButton {
                Layout.alignment: Qt.AlignLeft
                font.bold: true
                font.pixelSize: 12
                text: qsTrId('id_learn_more')
                textColor: toast.textColor
                onClicked: Qt.openUrlExternally(toast.notification.alert.link)
            }
        }
    }

    component UpdateToast: Toast {
        id: toast
        borderColor: '#7E2A0D'
        backgroundColor: '#432004'
        textColor: '#FFFFFF'
        
        contentItem: RowLayout {
            spacing: 8
            Layout.alignment: Qt.AlignCenter
            Image {
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                source: 'qrc:/svg2/warning-light.svg'
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Label {
                    Layout.fillWidth: true
                    color: toast.textColor
                    font.pixelSize: 14
                    font.weight: 700
                    text: 'Update Available'
                    wrapMode: Label.NoWrap
                    elide: Label.ElideRight
                }
                Label {
                    Layout.fillWidth: true
                    color: toast.textColor
                    font.pixelSize: 13
                    font.weight: 400
                    text: toast.notification.version
                          ? 'Version %1 is available. Please update to continue using the app.'
                                .arg(toast.notification.version)
                          : 'A new version is available. Please update to continue using the app.'
                    wrapMode: Label.WordWrap
                }
                PrimaryButton {
                    Layout.topMargin: 6
                    borderColor: '#FFFFFF'
                    fillColor: '#FFFFFF'
                    textColor: '#000000'
                    font.pixelSize: 12
                    font.weight: 600
                    text: 'Update'
                    padding: 6
                    leftPadding: 10
                    rightPadding: 10
                    topPadding: 6
                    bottomPadding: 6
                    onClicked: Qt.openUrlExternally('https://blockstream.com/app/')
                }
            }
            CloseButton {
                Layout.alignment: Qt.AlignTop
                onClicked: toast.slideOutAndDismiss()
            }
        }
    }
}
