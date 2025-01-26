import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

StackViewPage {
    signal submitted(var request)
    required property string type
    required property string subject
    property Context context
    RequestSupportController {
        id: controller
        onFailed: (error) => {
            self.enabled = true
            error_badge.raise('Your request failed', error)
        }
        onSubmitted: (result) => self.submitted(result.request)
    }
    id: self
    title: {
        if (self.type === 'incident') return 'Contact us'
        if (self.type === 'feedback') return 'Feedback'
        return qsTrId('id_support')
    }
    contentItem: Flickable {
        ScrollIndicator.vertical: ScrollIndicator {
            active: flickable.contentHeight > flickable.height
        }
        id: flickable
        clip: true
        contentWidth: flickable.width
        contentHeight: layout.height
        ColumnLayout {
            id: layout
            width: flickable.width
            Label {
                Layout.bottomMargin: 10
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                horizontalAlignment: Label.AlignHCenter
                text: 'Please be as detailed as possible when describing the issue'
                visible: type !== 'feedback'
                wrapMode: Label.Wrap
            }
            FieldTitle {
                text: qsTrId('id_email')
            }
            TTextField {
                Layout.bottomMargin: 10
                Layout.fillWidth: true
                id: email_field
                focus: true
                validator: RegularExpressionValidator {
                    regularExpression: /^(?:(?:[a-zA-Z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-zA-Z0-9!#$%&'*+/=?^_`{|}~-]+)*)|(?:".+"))@(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$/
                }
                onTextChanged: error_badge.clear()
            }
            FieldTitle {
                text: qsTrId('id_description')
            }
            GTextArea {
                Layout.bottomMargin: 10
                Layout.fillWidth: true
                Layout.minimumHeight: 200
                id: description_field
                onTextChanged: error_badge.clear()
            }
            Label {
                Layout.alignment: Qt.AlignRight
                color: '#FFF'
                font.pixelSize: 12
                font.weight: 400
                opacity: 0.6
                text: `${description_field.length}/1000`
            }
        }
    }
    footerItem: ColumnLayout {
        spacing: 10
        FixedErrorBadge {
            Layout.fillWidth: true
            Layout.bottomMargin: 20
            id: error_badge
            pointer: false
        }
        RowLayout {
            visible: self.type === 'incident'
            CheckBox {
                id: logs_checkbox
                checked: self.type === 'incident'
                onCheckedChanged: error_badge.clear()
            }
            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                text: qsTrId('Share logs')
                wrapMode: Label.Wrap
            }
        }
        RowLayout {
            visible: Settings.useTor
            CheckBox {
                id: tor_checkbox
            }
            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                text: qsTrId('I understand that asking for support through Tor will reduce my anonymity')
                wrapMode: Label.Wrap
            }
        }
        PrimaryButton {
            Layout.fillWidth: true
            busy: !self.enabled
            enabled: email_field.acceptableInput && description_field.length > 0 && description_field.length <= 1000 & (!Settings.useTor || tor_checkbox.checked)
            text: qsTrId('id_submit')
            onClicked: {
                error_badge.clear()
                const custom_fields = []
                if (self.context) {
                    const supportId = self.context.accounts
                        .filter(account => account.pointer === 0 && !account.network.electrum)
                        .map(account => `${account.network.data.bip21_prefix}:${account.json.receiving_id}`)
                        .join(',')
                    custom_fields.push({ id: '23833728377881', value: supportId })
                    const hww = self.context?.wallet?.login?.device?.type
                    if (hww) {
                        custom_fields.push({ id: '900006375926', value: hww })
                    }
                }

                self.enabled = false
                controller.submit(logs_checkbox.checked, {
                    type: self.type,
                    subject: self.subject,
                    email: email_field.text,
                    body: description_field.text,
                    custom_fields
                })
            }
        }
    }
}
