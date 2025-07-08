import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import QtMultimedia

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

ApplicationWindow {
    readonly property bool hasVideoInput: media_devices.videoInputs?.length > 0
    Constants {
        id: constants
    }
    id: window
    x: Settings.windowX
    y: Settings.windowY
    width: Settings.windowWidth
    height: Settings.windowHeight
    onXChanged: Settings.windowX = x
    onYChanged: Settings.windowY = y
    onWidthChanged: Settings.windowWidth = width
    onHeightChanged: Settings.windowHeight = height
    minimumWidth: 900
    minimumHeight: 600
    visible: true
    color: '#121416'
    title: {
        const title = stack_view.currentItem?.title
        const parts = []
        if (title) parts.push(title)
        parts.push('Blockstream Green');
        if (env !== 'Production') parts.push(`[${env}]`)
        return parts.join(' - ');
    }
    onClosing: (event) => {
        event.accepted = false
        controller.triggerQuit()
    }
    ApplicationController {
        id: controller
        onQuitRequested: controller.triggerQuit()
        onQuitTriggered: {
            Settings.windowX = window.x
            Settings.windowY = window.y
            Settings.windowWidth = window.width
            Settings.windowHeight = window.height
            stack_view.replace(null, quit_page, StackView.PushTransition)
        }
    }

    MediaDevices {
        id: media_devices
    }

    GStackView {
        id: stack_view
        anchors.fill: parent
        initialItem: splash_page
    }

    Component {
        id: quit_page
        Item {
            StackView.onActivated: {
                window.hide()
                controller.quit()
            }
        }
    }

    Component {
        id: splash_page
        SplashPage {
            onTimeout: {
                if (Settings.analytics === '') {
                    stack_view.replace(null, analytics_consent_page, StackView.PushTransition)
                } else {
                    app_page.active = true
                }
            }
        }
    }

    property bool splashDone: false
    function pushAppPage() {
        if (!consent_dialog.visible && window.splashDone) {
            app_page.active = true
        }
    }

    Loader {
        id: app_page
        active: false
        visible: false
        asynchronous: true
        onLoaded: stack_view.replace(null, app_page.item, StackView.PushTransition)
        sourceComponent: AppPage {
            StackView.onActivated: controller.reportCrashes()
            StackView.onDeactivated: app_page.active = false
            onCrashClicked: controller.triggerCrash()
        }
    }


    Component {
        id: analytics_consent_page
        AnalyticsConsentPage {
            onDone: app_page.active = true
        }
    }
}
