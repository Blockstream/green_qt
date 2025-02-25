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
                if (!consent_dialog.visible) {
                    app_page.active = true
                }
            }
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

    AnalyticsConsentDialog {
        property real offset_y
        id: consent_dialog
        x: parent.width - consent_dialog.width - constants.s2
        y: parent.height - consent_dialog.height - constants.s2 - 30 + consent_dialog.offset_y
        // by default dialogs height depends on y, break that dependency to avoid binding loop on y
        onClosed: app_page.active = true
        height: implicitHeight
        visible: Settings.analytics === ''
        enter: Transition {
            SequentialAnimation {
                PropertyAction { property: 'x'; value: 0 }
                PropertyAction { property: 'offset_y'; value: 100 }
                PropertyAction { property: 'opacity'; value: 0 }
                PauseAnimation { duration: 2000 }
                ParallelAnimation {
                    NumberAnimation { property: 'opacity'; to: 1; easing.type: Easing.OutCubic; duration: 1000 }
                    NumberAnimation { property: 'offset_y'; to: 0; easing.type: Easing.OutCubic; duration: 1000 }
                }
            }
        }
    }
}
