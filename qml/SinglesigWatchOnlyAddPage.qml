import Blockstream.Green
import Blockstream.Green.Core
import QtCore
import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
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
                spacing: 10
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
                Label {
                    Layout.alignment: Qt.AlignCenter
                    Layout.fillWidth: true
                    Layout.maximumWidth: 400
                    Layout.preferredWidth: 0
                    Layout.topMargin: 30
                    font.pixelSize: 14
                    font.weight: 400
                    horizontalAlignment: Label.AlignHCenter
                    opacity: 0.4
                    text: selector.index === 0 ? qsTrId('id_scan_or_paste_your_extended') : qsTrId('id_scan_or_paste_your_public')
                    wrapMode: Label.Wrap
                }
                KeysField {
                    Layout.alignment: Qt.AlignCenter
                    Layout.fillWidth: true
                    id: keys_field
                    focus: true
                    onTextChanged: {
                        error_badge.clear()
                        selector.index = keys_field.text.indexOf('(') < 0 ? 0 : 1
                    }
                }
                PrimaryButton {
                    Layout.alignment: Qt.AlignCenter
                    Layout.fillWidth: true
                    Layout.topMargin: 40
                    text: qsTrId('id_import')
                    action: Action {
                        id: login_action
                        onTriggered: {
                            onTextEdited: error_badge.clear()
                            if (selector.index === 0) {
                                controller.loginExtendedPublicKeys(keys_field.text)
                            } else {
                                controller.loginDescriptors(keys_field.text)
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
                enabled: !self.network.liquid && keys_field.text.indexOf('(') < 0
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


    component KeysField: TextArea {
        Layout.minimumHeight: options_layout.height + text_area.topPadding + text_area.bottomPadding
        id: text_area
        topPadding: 14
        bottomPadding: 14
        leftPadding: 15
        rightPadding: 15 + options_layout.width + 10
        font.pixelSize: 14
        font.weight: 500
        wrapMode: TextEdit.Wrap
        background: Rectangle {
            color: Qt.lighter('#222226', text_area.hovered ? 1.2 : 1)
            radius: 5
            Rectangle {
                border.width: 2
                border.color: '#00B45A'
                color: 'transparent'
                radius: 9
                anchors.fill: parent
                anchors.margins: -4
                z: -1
                opacity: {
                    if (self.activeFocus) {
                        switch (self.focusReason) {
                        case Qt.TabFocusReason:
                        case Qt.BacktabFocusReason:
                        case Qt.ShortcutFocusReason:
                            return 1
                        }
                    }
                    return 0
                }
            }
        }
        Column {
            id: options_layout
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 15
            spacing: 16
            CircleButton {
                enabled: text_area.text.length > 0
                icon.source: 'qrc:/svg2/x-circle.svg'
                onClicked: text_area.clear()
            }
            CircleButton {
                icon.source: 'qrc:/svg2/paste.svg'
                onClicked: {
                    text_area.clear();
                    text_area.paste();
                }
            }
            CircleButton {
                enabled: !scanner_popup.visible
                icon.source: 'qrc:/svg2/qrcode.svg'
                onClicked: scanner_popup.open()
                ScannerPopup {
                    id: scanner_popup
                    onCodeScanned: (code) => {
                        text_area.text = code
                    }
                }
            }
            CircleButton {
                icon.source: 'qrc:/svg2/import.svg'
                onClicked: file_dialog.open()
            }
        }
        FileDialog {
            id: file_dialog
            currentFolder: StandardPaths.standardLocations(StandardPaths.DesktopLocation)[0]
            onAccepted: {
                const xpubs = controller.parseFile(file_dialog.selectedFile)
                if (xpubs.length) {
                    text_area.text = xpubs.join('\n')
                }
            }
        }
    }
}
