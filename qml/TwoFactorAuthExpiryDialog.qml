import Blockstream.Green
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

WalletDialog {
    required property Session session

    onClosed: self.destroy()

    id: self
    title: qsTrId('id_twofactor_authentication_expiry')
    clip: true
    header: null
    width: 500
    Overlay.modal: Rectangle {
        anchors.fill: parent
        color: 'black'
        opacity: 0.6
    }

    TwoFactorController {
        id: controller
        context: self.context
        session: self.session
        onFailed: (error) => stack_view.replace(null, error_page, { error }, StackView.PushTransition)
        onFinished: self.accept()
    }

    TaskPageFactory {
        title: self.title
        monitor: controller.monitor
        target: stack_view
    }

    Component {
        id: error_page
        ErrorPage {
            title: self.title
            rightItem: CloseButton {
                onClicked: self.close()
            }
        }
    }

    contentItem: GStackView {
        id: stack_view
        implicitWidth: Math.max(500, stack_view.currentItem.implicitWidth)
        implicitHeight: Math.max(0, stack_view.currentItem.implicitHeight)
        initialItem: StackViewPage {
            StackView.onActivated: controller.monitor.clear()
            footer: null
            title: self.title
            rightItem: CloseButton {
                onClicked: self.close()
            }
            contentItem: ColumnLayout {
                spacing: 10
                Option {
                    index: 0
                    description: qsTrId('id_optimal_if_you_spend_coins')
                }
                Option {
                    index: 1
                    description: qsTrId('id_wallet_coins_will_require')
                }
                Option {
                    index: 2
                    description: qsTrId('id_optimal_if_you_rarely_spend')
                }
            }
        }
    }

    component Option: AbstractButton {
        required property int index
        required property string description
        readonly property int value: self.session.network.data.csv_buckets[option.index]
        Layout.fillWidth: true
        id: option
        enabled: self.session.settings.csvtime !== option.value
        opacity: option.enabled ? 1 : 0.6
        padding: 20
        text: UtilJS.csvLabel(option.value)
        background: Rectangle {
            radius: 5
            color: Qt.lighter('#222226', option.enabled && option.hovered ? 1.2 : 1)
        }
        contentItem: RowLayout {
            spacing: 20
            ColumnLayout {
                spacing: 10
                Label {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    font.pixelSize: 14
                    font.weight: 600
                    text: UtilJS.csvLabel(option.value)
                    wrapMode: Text.WordWrap
                }
                Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    font.pixelSize: 14
                    font.weight: 500
                    text: option.description
                    wrapMode: Text.WordWrap
                }
            }
            Image {
                Layout.alignment: Qt.AlignCenter
                source: 'qrc:/svg2/next_arrow.svg'
            }
        }
        onClicked: controller.setCsvTime(option.value)
    }
}
