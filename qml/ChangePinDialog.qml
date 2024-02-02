import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS

WalletDialog {
    property string pin
    property bool changed: false

    onClosed: self.destroy()

    id: self
    title: qsTrId('id_change_pin')
    header: null
    Overlay.modal: Rectangle {
        anchors.fill: parent
        color: 'black'
        opacity: 0.6
    }

    Controller {
        id: controller
        context: self.context
        onFinished: stack_view.replace(null, ok_page, StackView.PushTransition)
    }

    AnalyticsView {
        active: self.opened
        name: 'WalletSettingsChangePIN'
        segmentation: AnalyticsJS.segmentationSession(self.wallet)
    }

    TaskPageFactory {
        title: self.title
        monitor: controller.monitor
        target: stack_view
    }

    contentItem: GStackView {
        id: stack_view
        implicitWidth: Math.max(400, stack_view.currentItem.implicitWidth)
        implicitHeight: Math.max(400, stack_view.currentItem.implicitHeight)
        initialItem: StackViewPage {
            title: self.title
            rightItem: CloseButton {
                onClicked: self.close()
            }
            contentItem: ColumnLayout {
                VSpacer {
                }
                PinField {
                    Layout.alignment: Qt.AlignCenter
                    id: pin_field
                    focus: true
                    onPinEntered: pin => {
                        if (self.pin) {
                            if (self.pin === pin) {
                                pin_field.enabled = false
                                controller.changePin(self.pin)
                            } else {
                                self.pin = null
                                pin_field.enabled = false
                                pin_field.clear()
                                info_label.text = qsTrId('id_pins_do_not_match_please_try')
                                timer.start()

                            }
                        } else {
                            self.pin = pin
                            pin_field.enabled = false
                            info_label.text = qsTrId('id_verify_your_pin')
                            timer.start()
                        }
                    }
                }
                Timer {
                    id: timer
                    interval: 300
                    repeat: false
                    onTriggered: {
                        pin_field.clear()
                        pin_field.enabled = true
                    }
                }

                Label {
                    Layout.alignment: Qt.AlignCenter
                    Layout.bottomMargin: 30
                    id: info_label
                    font.pixelSize: 12
                    font.weight: 600
                    horizontalAlignment: Qt.AlignHCenter
                    text: qsTrId('id_set_a_new_pin')
                    wrapMode: Label.WordWrap
                }
                PinPadButton {
                    Layout.alignment: Qt.AlignCenter
                    enabled: pin_field.enabled
                    target: pin_field
                }
                VSpacer {
                }
            }
        }
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
                    text: qsTrId('id_you_have_successfully_changed')
                    wrapMode: Label.Wrap
                }
                VSpacer {
                }
            }
        }
    }
}
