import Blockstream.Green
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

WalletDrawer {
    property string title: qsTrId('id_twofactor_authentication_expiry')
    required property Session session

    TwoFactorController {
        id: controller
        context: self.context
        session: self.session
        onFailed: (error) => stack_view.replace(null, error_page, { error }, StackView.PushTransition)
        onFinished: self.close()
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

    id: self
    contentItem: GStackView {
        id: stack_view
        initialItem: StackViewPage {
            StackView.onActivated: controller.monitor.clear()
            footer: null
            title: self.title
            rightItem: CloseButton {
                onClicked: self.close()
            }
            contentItem: ColumnLayout {
                enabled: controller.monitor.idle
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
                VSpacer {
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
        checked: self.session.settings.csvtime === option.value
        focusPolicy: Qt.StrongFocus
        padding: 20
        text: UtilJS.csvLabel(option.value)
        background: Rectangle {
            radius: 5
            color: Qt.lighter(option.checked ? '#062F4A' : '#181818', option.hovered ? 1.2 : 1)
            border.width: option.visualFocus ? 2 : 1
            border.color: option.visualFocus || option.checked ? '#00BCFF' : '#262626'
        }
        contentItem: RowLayout {
            spacing: 0
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
                Layout.leftMargin: 10
                Layout.alignment: Qt.AlignCenter
                source: 'qrc:/svg2/check.svg'
                visible: option.checked
            }
        }
        onClicked: controller.setCsvTime(option.value)
    }
}
