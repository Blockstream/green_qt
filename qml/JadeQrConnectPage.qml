import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

StackViewPage {
    signal loginFinished(Context context)

    // Switches between the instructions view and the QR scanner view
    property bool scanning: false
    // Guards against the camera triggering login multiple times for the same QR
    property bool busy: false

    AnalyticsView {
        active: true
        name: 'OnBoardWatchOnlyCredentials'
        segmentation: AnalyticsJS.segmentationSession(Settings, controller.context)
    }

    WatchOnlyLoginController {
        id: controller
        persist: remember_checkbox.checked
        onLoginFinished: {
            if (controller.persist) {
                Analytics.recordEvent('wallet_restore_watch_only', AnalyticsJS.segmentationSession(Settings, controller.context))
            }
            self.loginFinished(controller.context)
        }
        onLoginFailed: (error) => {
            self.busy = false
            self.scanning = false
            if (error === 'decode' || error === 'too short') {
                error = 'id_invalid_xpub'
            }
            error_badge.raise(error)
        }
    }

    function startLogin(text) {
        if (self.busy || !text) return
        self.busy = true
        controller.network = NetworkManager.network(UtilJS.networkFromDescriptor(text))
        controller.loginDescriptors(text)
    }

    id: self
    title: qsTrId('id_connect_via_qr')
    footer: null
    padding: 60
    rightItem: LinkButton {
        external: true
        text: qsTrId('id_learn_more')
        onClicked: Qt.openUrlExternally('https://help.blockstream.com/hc/en-us/articles/20272957303577-Add-Jade-to-a-QR-supported-app')
    }

    ColumnLayout {
        Layout.alignment: Qt.AlignCenter
        Layout.maximumWidth: 500
        visible: !self.scanning
        spacing: 10
        Image {
            Layout.alignment: Qt.AlignCenter
            Layout.preferredHeight: 220
            antialiasing: true
            fillMode: Image.PreserveAspectFit
            mipmap: true
            smooth: true
            source: 'qrc:/svg3/jade_welcome.svg'
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            Layout.topMargin: 20
            font.pixelSize: 26
            font.weight: 600
            horizontalAlignment: Label.AlignHCenter
            text: 'Import public key'
            wrapMode: Label.WordWrap
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            Layout.maximumWidth: 420
            Layout.preferredWidth: 0
            Layout.topMargin: 10
            font.pixelSize: 14
            font.weight: 400
            horizontalAlignment: Label.AlignHCenter
            opacity: 0.6
            text: qsTrId('id_navigate_on_your_jade_to')
            wrapMode: Label.WordWrap
        }
        PrimaryButton {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            Layout.topMargin: 40
            text: qsTrId('id_continue')
            onClicked: {
                error_badge.clear()
                self.scanning = true
            }
        }
        RegularButton {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            Layout.topMargin: 10
            text: qsTrId('id_qr_pin_unlock')
            cyan: true
            onClicked: self.StackView.view.push(qrunlock_page)
        }
        FixedErrorBadge {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 20
            id: error_badge
            pointer: false
        }
        CheckBox {
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 10
            id: remember_checkbox
            checked: true
            text: qsTrId('id_remember_me')
            leftPadding: 12
            rightPadding: 12
            topPadding: 8
            bottomPadding: 8
            background: Rectangle {
                color: '#282D38'
                border.width: 1
                border.color: '#FFF'
                radius: 5
            }
        }
    }

    // --- Scanner view ---
    ColumnLayout {
        Layout.alignment: Qt.AlignCenter
        visible: self.scanning
        spacing: 20
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            font.pixelSize: 18
            font.weight: 600
            horizontalAlignment: Label.AlignHCenter
            text: qsTrId('id_scan_qr_code')
            wrapMode: Label.WordWrap
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            Layout.maximumWidth: 420
            Layout.preferredWidth: 0
            Layout.topMargin: 10
            font.pixelSize: 14
            font.weight: 400
            horizontalAlignment: Label.AlignHCenter
            opacity: 0.6
            text: qsTrId('id_navigate_on_your_jade_to')
            wrapMode: Label.WordWrap
        }
        Loader {
            Layout.alignment: Qt.AlignCenter
            Layout.minimumWidth: 350
            Layout.minimumHeight: 350
            // Instantiate (and start the camera) only while scanning and not busy
            active: self.scanning && !self.busy
            visible: active
            sourceComponent: ScannerView {
                onBcurScanned: (result) => {
                    if (result.ur_type === 'crypto-account') {
                        self.startLogin(result.descriptors.join('\n'))
                    }
                }
                onCodeScanned: (code) => self.startLogin(code)
            }
        }
        BusyIndicator {
            Layout.alignment: Qt.AlignCenter
            running: self.busy
            visible: self.busy
        }
    }

    Component {
        id: qrunlock_page
        JadeQrConnectUnlockPage {
            returnPage: self
        }
    }
}
