import Blockstream.Green
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

WalletDialog {
    required property Session session

    property var currencies: [{
        is_fiat: false,
        text: self.session.unit
    }, {
        is_fiat: true,
        text: self.session.settings.pricing.currency
    }]

    readonly property string unit: {
        const unit = self.session.unit
        return unit === '\u00B5BTC' ? 'ubtc' : unit.toLowerCase()
    }

    property string threshold: self.session.config.limits.is_fiat ? self.session.config.limits.fiat : self.session.config.limits[unit]
    property string ticker: self.session.config.limits.is_fiat ? self.session.settings.pricing.currency : unit

    onClosed: self.destroy()

    id: self
    title: qsTrId('id_set_twofactor_threshold')
    clip: true
    header: null
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
        onFinished: stack_view.replace(null, ok_page, StackView.PushTransition)
    }

    TaskPageFactory {
        title: self.title
        monitor: controller.monitor
        target: stack_view
    }

    Component {
        id: ok_page
        StackViewPage {
            title: self.title
            rightItem: CloseButton {
                onClicked: self.close()
            }
            contentItem: ColumnLayout {
                spacing: 20
                Convert {
                    id: threshold_convert
                    context: self.session.context
                    account: self.session.context.getOrCreateAccount(self.session.network, 0)
                    input: {
                        if (self.session.config.limits.is_fiat) {
                            return { fiat: self.session.config.limits.fiat }
                        } else {
                            return { satoshi: self.session.config.limits.satoshi }
                        }
                    }
                    unit: self.session.unit
                }
                VSpacer {
                }
                CompletedImage {
                    Layout.alignment: Qt.AlignCenter
                }
                Label {
                    Layout.alignment: Qt.AlignCenter
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    Layout.topMargin: 10
                    Layout.bottomMargin: 20
                    horizontalAlignment: Label.AlignHCenter
                    font.pixelSize: 14
                    font.weight: 400
                    text: qsTrId('id_your_twofactor_threshold_is_s').arg(threshold_convert.output.label)
                    wrapMode: Label.Wrap
                }
                VSpacer {
                }
            }
        }
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
            title: self.title
            rightItem: CloseButton {
                onClicked: self.close()
            }
            contentItem: ColumnLayout {
                spacing: 10
                Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    Layout.minimumWidth: 400
                    text: qsTrId('id_spend_your_bitcoin_without_2fa')
                    wrapMode: Label.Wrap
                }
                FieldTitle {
                    Layout.topMargin: 15
                    text: qsTrId('id_amount')
                }
                AmountField {
                    Layout.bottomMargin: 15
                    id: amount_field
                    dynamic: false
                    unit: self.session.unit
                    convert: Convert {
                        context: self.session.context
                        account: self.session.context.getOrCreateAccount(self.session.network, 0)
                        input: {
                            if (self.session.config.limits.is_fiat) {
                                return { fiat: self.session.config.limits.fiat }
                            } else {
                                return { satoshi: self.session.config.limits.satoshi }
                            }
                        }
                        unit: self.session.unit
                    }
                }
                VSpacer {
                }
            }
            footer: Pane {
                background: null
                padding: 20
                contentItem: RowLayout {
                    spacing: 10
                    PrimaryButton {
                        Layout.alignment: Qt.AlignCenter
                        Layout.minimumWidth: 150
                        busy: !controller.monitor.idle
                        enabled: controller.monitor.idle
                        text: qsTrId('id_next')
                        onClicked: {
                            controller.changeLimits(amount_field.convert.result.satoshi)
                        }
                    }
                }
            }
        }
    }
}
