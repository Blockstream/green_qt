import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS

Dialog {
    required property Context context
    required property JadeHttpRequest request
    function openSupport() {
        const version = Qt.application.version
        const url = `https://help.blockstream.com/hc/en-us/requests/new?tf_900008231623=${platform}&tf_subject=Non-default PIN server&&tf_900003758323=blockstream_jade&tf_900006375926=jade&tf_900009625166=${version}`
        Qt.openUrlExternally(url);
    }
    Component.onCompleted: {
        Analytics.recordEvent('custom_pin_server_warning', AnalyticsJS.segmentationSession(Settings, self.context))
    }
    onClosed: self.destroy()
    id: self
    objectName: "JadeHttpRequestDialog"
    clip: true
    closePolicy: Popup.NoAutoClose
    modal: true
    anchors.centerIn: parent
    topPadding: 20
    bottomPadding: 20
    leftPadding: 20
    rightPadding: 20
    width: 400
    height: 550
    Overlay.modal: MultiEffect {
        anchors.fill: parent
        autoPaddingEnabled: false
        brightness: self.visible ? -0.05 : 0
        Behavior on brightness {
            NumberAnimation { duration: 200 }
        }
        blurEnabled: true
        blurMax: 64
        blur: self.visible ? 1 : 0
        Behavior on blur {
            NumberAnimation { duration: 200 }
        }
        source: ApplicationWindow.contentItem
    }
    background: Rectangle {
        anchors.fill: parent
        radius: 10
        color: '#9A0000'
        border.width: 0.5
        border.color: Qt.lighter('#9A0000')
    }
    contentItem: GStackView {
        id: stack_view
        initialItem: alert_page
    }

    Component {
        id: alert_page
        AlertPage {
        }
    }

    Component {
        id: advanced_page
        AdvancedPage {
        }
    }

    component AlertPage: StackViewPage {
        rightItem: CloseButton {
            onClicked: {
                self.request.reject()
                self.reject()
            }
        }
        contentItem: ColumnLayout {
            spacing: 10
            RowLayout {
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: false
                spacing: 10
                Image {
                    source: 'qrc:/svg2/alert.svg'
                }
                Label {
                    Layout.alignment: Qt.AlignCenter
                    font.pixelSize: 16
                    font.weight: 790
                    text: qsTrId('id_warning')
                }
            }
            VSpacer {
            }
            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                font.pixelSize: 16
                font.weight: 790
                horizontalAlignment: Label.AlignHCenter
                text: 'Connection Blocked'
                wrapMode: Label.WordWrap
            }
            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                font.pixelSize: 14
                font.weight: 457
                horizontalAlignment: Label.AlignHCenter
                opacity: 0.6
                text: 'Jade is trying to connect to a non-default blind PIN oracle. Contact support immediately for further information.'
                wrapMode: Label.WordWrap
            }
            VSpacer {
            }
            PrimaryButton {
                Layout.fillWidth: true
                borderColor: '#FFFFFF'
                fillColor: '#FFFFFF'
                textColor: '#000000'
                text: qsTrId('id_support')
                onClicked: self.openSupport()
            }
            RegularButton {
                Layout.fillWidth: true
                text: qsTrId('id_advanced')
                onClicked: stack_view.push(advanced_page)
            }
        }
    }

    component AdvancedPage: StackViewPage {
        rightItem: CloseButton {
            onClicked: {
                self.request.reject()
                self.reject()
            }
        }
        contentItem: ColumnLayout {
            id: layout
            enabled: !self.request.busy
            spacing: 10
            RowLayout {
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: false
                spacing: 10
                Image {
                    source: 'qrc:/svg2/alert.svg'
                }
                Label {
                    Layout.alignment: Qt.AlignCenter
                    font.pixelSize: 16
                    font.weight: 790
                    text: qsTrId('id_warning')
                }
            }
            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                font.pixelSize: 14
                font.weight: 600
                horizontalAlignment: Label.AlignHCenter
                text: 'Connection attempt to:'
                wrapMode: Label.WordWrap
            }
            Repeater {
                model: self.request.hosts.filter(host => host.length > 0)
                delegate: Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    font.pixelSize: 14
                    font.weight: 600
                    horizontalAlignment: Label.AlignHCenter
                    text: modelData
                    wrapMode: Label.WrapAnywhere
                }
            }
            VSpacer {
            }
            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                font.pixelSize: 14
                font.weight: 600
                horizontalAlignment: Label.AlignHCenter
                text: 'This is not the default blind PIN oracle'
                wrapMode: Label.WordWrap
            }
            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                horizontalAlignment: Label.AlignHCenter
                opacity: 0.6
                text: 'If you did not change your oracle settings on Jade, do not proceed and contact Blockstream support.'
                wrapMode: Label.WordWrap
            }
            VSpacer {
            }
            PrimaryButton {
                Layout.fillWidth: true
                borderColor: '#FFFFFF'
                fillColor: '#FFFFFF'
                textColor: '#000000'
                text: qsTrId('id_support')
                onClicked: self.openSupport()
            }
            RegularButton {
                Layout.fillWidth: true
                text: 'Allow Non-Default Connection'
                busy: self.request.busy
                onClicked: {
                    Analytics.recordEvent('custom_pin_server_connect', AnalyticsJS.segmentationSession(Settings, self.context))
                    self.request.accept(remember_checkbox.checked)
                    self.accept()
                }
            }
            CheckBox {
                Layout.alignment: Qt.AlignCenter
                id: remember_checkbox
                text: qsTrId('id_dont_ask_me_again')
            }
        }
    }
}
