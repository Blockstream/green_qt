import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS

StackViewPage {
    signal loginFinished(Context context)
    required property Network network
    AnalyticsView {
        active: true
        name: 'OnBoardWatchOnlyCredentials'
        segmentation: AnalyticsJS.segmentationSession(Settings, controller.context)
    }
    WatchOnlyLoginController {
        id: controller
        network: self.network
        persist: remember_checkbox.checked
        onLoginFinished: {
            self.loginFinished(controller.context)
            if (controller.persist) {
                Analytics.recordEvent('wallet_restore_watch_only', AnalyticsJS.segmentationSession(Settings, controller.context))
            }
        }
        onLoginFailed: (error) => {
            console.log('login failed', error)
            error_badge.error = error
        }
    }
    id: self
    padding: 60
    contentItem: ColumnLayout {
        VSpacer {
        }
        Pane {
            Layout.alignment: Qt.AlignCenter
            Layout.maximumWidth: 500
            background: null
            contentItem: ColumnLayout {
                Label {
                    Layout.alignment: Qt.AlignCenter
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    font.pixelSize: 26
                    font.weight: 600
                    horizontalAlignment: Label.AlignHCenter
                    text: qsTrId('id_watchonly_details')
                    wrapMode: Label.WordWrap
                }
                Selector {
                    Layout.alignment: Qt.AlignCenter
                    Layout.topMargin: 20
                    id: selector
                    index: self.network.liquid ? 1 : 0
                }
                Pane {
                    Layout.fillWidth: true
                    Layout.topMargin: 30
                    visible: selector.index === 0
                    background: null
                    contentItem: ColumnLayout {
                        Label {
                            Layout.alignment: Qt.AlignCenter
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                            font.pixelSize: 14
                            font.weight: 400
                            horizontalAlignment: Label.AlignHCenter
                            opacity: 0.4
                            text: qsTrId('id_scan_or_paste_your_extended')
                            wrapMode: Label.Wrap
                        }
                        XPubField {
                            Layout.alignment: Qt.AlignCenter
                            Layout.fillWidth: true
                            id: xpub_field
                            focus: true
                            network: self.network
                            validator: null
                            onAccepted: xpub_login_action.trigger()
                            onTextEdited: error_badge.clear()
                        }
                        PrimaryButton {
                            Layout.alignment: Qt.AlignCenter
                            Layout.fillWidth: true
                            Layout.topMargin: 40
                            text: qsTrId('id_import')
                            action: Action {
                                id: xpub_login_action
                                enabled: xpub_field.acceptableInput
                                onTriggered: {
                                    onTextEdited: error_badge.clear()
                                    controller.loginExtendedPublicKeys(xpub_field.text)
                                }
                            }
                        }
                    }
                }
                Pane {
                    Layout.fillWidth: true
                    Layout.topMargin: 30
                    visible: selector.index === 1
                    background: null
                    contentItem: ColumnLayout {
                        Label {
                            Layout.alignment: Qt.AlignCenter
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                            font.pixelSize: 14
                            font.weight: 400
                            horizontalAlignment: Label.AlignHCenter
                            opacity: 0.4
                            text: qsTrId('id_scan_or_paste_your_public')
                            wrapMode: Label.Wrap
                        }
                        DescriptorField {
                            Layout.fillWidth: true
                            id: descriptor_field
                            focus: true
                            network: self.network
                            validator: null
                            onAccepted: descriptor_login_action.trigger()
                            onTextEdited: error_badge.clear()
                        }
                        PrimaryButton {
                            Layout.alignment: Qt.AlignCenter
                            Layout.fillWidth: true
                            Layout.topMargin: 40
                            text: qsTrId('id_import')
                            action: Action {
                                id: descriptor_login_action
                                enabled: descriptor_field.acceptableInput
                                onTriggered: {
                                    onTextEdited: error_badge.clear()
                                    controller.loginDescriptors(descriptor_field.text)
                                }
                            }
                        }
                    }
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
                Label {
                    Layout.topMargin: 30
                    Layout.fillWidth: true
                    font.pixelSize: 14
                    font.weight: 400
                    horizontalAlignment: Label.AlignHCenter
                    opacity: 0.4
                    text: 'Watch-only wallets let you receive funds and check your balance.'
                    wrapMode: Label.WordWrap
                }
            }
        }
        VSpacer {
        }
    }

    component Selector: Pane {
        property int index: 0
        Layout.alignment: Qt.AlignCenter
        id: selector
        padding: 0
        background: Rectangle {
            border.width: 0.5
            border.color: '#313131'
            color: '#121414'
            radius: 4
        }
        contentItem: RowLayout {
            spacing: 0
            Option {
                text: qsTrId('id_xpub')
                enabled: !self.network.liquid
                checked: selector.index === 0
                onClicked: selector.index = 0
            }
            Option {
                text: qsTrId('id_descriptor')
                checked: selector.index === 1
                onClicked: selector.index = 1
            }
        }
    }
    component Option: AbstractButton {
        required property int index
        id: option
        implicitHeight: 35
        implicitWidth: 163
        background: Item {
            Rectangle {
                anchors.fill: parent
                visible: option.checked
                border.width: option.checked ? 1 : 0.5
                border.color: Qt.alpha('#FFF', 0.3)
                color: '#3A3A3D'
                radius: 4
            }
            Rectangle {
                anchors.fill: parent
                anchors.margins: -4
                border.width: 2
                border.color: '#00B45A'
                color: 'transparent'
                radius: 8
                visible: option.enabled && option.visualFocus
            }
        }
        contentItem: Label {
            font.pixelSize: 12
            font.weight: 600
            horizontalAlignment: Label.AlignHCenter
            verticalAlignment: Label.AlignVCenter
            opacity: option.checked ? 1 : 0.3
            text: option.text
        }
    }
}
