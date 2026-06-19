import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    required property Context context
    required property string invoice
    required property var amountSats
    required property var fundingFeeSats
    required property date expiresAt

    property bool paid: false
    property string note: ''

    readonly property Asset asset: self.context.getOrCreateAsset('lnbtc')
    readonly property string invoiceUri: 'lightning:' + self.invoice.toUpperCase()
    readonly property var amountToReceiveSats: amountSats > fundingFeeSats ? amountSats - fundingFeeSats : 0;

    id: self
    title: qsTrId('id_lightning_invoice')
    rightItem: CloseButton {
        onClicked: self.closeClicked()
    }
    footerItem: PrimaryButton {
        Layout.fillWidth: true
        icon.source: copy_timer.running ? 'qrc:/000000/24/check.svg' : 'qrc:/000000/24/clipboard.svg'
        text: copy_timer.running ? 'Copied' : 'Copy Invoice'
        onClicked: {
            Clipboard.copy(self.invoiceUri)
            copy_timer.restart()
        }
        Timer {
            id: copy_timer
            repeat: false
            interval: 1000
        }
    }

    Connections {
        target: self.context?.lightningSession ?? null
        function onInvoicePaid(bolt11Invoice, amountSatoshi) {
            if (self.paid || bolt11Invoice !== self.invoice) return
            self.paid = true
            self.pushPage(invoice_paid_page)
        }
    }

    Convert {
        id: received_convert
        asset: self.asset
        context: self.context
        input: ({ satoshi: String(self.amountToReceiveSats) })
        unit: self.context.primarySession.unit
    }

    contentItem: VFlickable {
        alignment: Qt.AlignTop
        spacing: 12

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12

            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                color: '#A0A0A0'
                font.pixelSize: 14
                font.weight: 400
                horizontalAlignment: Label.AlignHCenter
                text: {
                    if (!self.expiresAt || isNaN(self.expiresAt.getTime())) return ''
                    return 'Expires %1'.arg(Qt.formatDateTime(self.expiresAt, Qt.DefaultLocaleLongDate))
                }
                visible: text.length > 0
                wrapMode: Label.WordWrap
            }

            QRCode {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 12
                id: qrcode
                text: self.invoiceUri
                implicitHeight: 256
                implicitWidth: 256
                radius: 8
                border: 4
                color: '#DFB316'
                corners: true
                Image {
                    anchors.centerIn: parent
                    source: 'qrc:/svg3/lightning.svg'
                }
            }

            AddressLabel {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                Layout.maximumWidth: 240
                Layout.topMargin: 8
                address: self.invoice
                accentColor: '#DFB316'
            }

            PrimaryButton {
                Layout.topMargin: 8
                Layout.alignment: Qt.AlignHCenter
                id: qr_button
                topPadding: 10
                bottomPadding: 10
                font.pixelSize: 14
                fillColor: qr_button.hovered ? '#062F4A' : 'transparent'
                textColor: '#00BCFF'
                text: 'Enlarge QR'
                onClicked: self.StackView.view.push(qrcode_page)
            }
            NoteCard {
                visible: self.note.length > 0
            }
            VSpacer {
                Layout.minimumHeight: 12
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12
                FeeRow {
                    visible: self.fundingFeeSats > 0
                    title: 'Funding Fee'
                    satoshi: self.fundingFeeSats
                    subtle: true
                }
                FeeRow {
                    title: qsTrId('id_amount_to_receive')
                    satoshi: self.amountToReceiveSats
                    subtle: false
                }
            }
        }
    }

    Component {
        id: invoice_paid_page
        InvoicePaidPage {
            receivedLabel: received_convert.output.label
            onCloseClicked: self.closeClicked()
        }
    }

    Component {
        id: qrcode_page
        StackViewPage {
            title: qsTrId('id_qr_code')
            contentItem: ColumnLayout {
                spacing: 20
                id: layout
                VSpacer {
                }
                QRCode {
                    Layout.fillWidth: true
                    Layout.minimumHeight: layout.width
                    Layout.alignment: Qt.AlignHCenter
                    layer.enabled: true
                    radius: 4
                    border: 16
                    text: self.invoiceUri
                    opacity: slider.value
                }
                RowLayout {
                    Layout.alignment: Qt.AlignCenter
                    Image {
                        source: 'qrc:/svg2/sun-dim.svg'
                    }
                    Slider {
                        Layout.maximumWidth: 120
                        id: slider
                        from: 0.4
                        to: 1
                        value: 1
                    }
                    Image {
                        source: 'qrc:/svg2/sun.svg'
                    }
                }
                VSpacer {
                }
            }
        }
    }

    component NoteCard: ColumnLayout {
        Layout.fillWidth: true
        spacing: 4

        Label {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            color: '#A0A0A0'
            font.pixelSize: 14
            font.weight: 400
            text: qsTrId('id_note')
            wrapMode: Label.WordWrap
        }
        Pane {
            Layout.fillWidth: true
            horizontalPadding: 16
            verticalPadding: 14
            background: Rectangle {
                border.color: '#262626'
                border.width: 1
                color: '#181818'
                radius: 4
            }
            contentItem: Label {
                color: '#FAFAFA'
                font.pixelSize: 14
                font.weight: 400
                text: self.note
                wrapMode: Label.WordWrap
            }
        }
    }

    component FeeRow: RowLayout {
        required property string title
        required property var satoshi
        property bool subtle: false

        Layout.fillWidth: true
        spacing: 10

        Convert {
            id: row_convert
            asset: self.asset
            context: self.context
            input: ({ satoshi: String(row.satoshi) })
            unit: self.context.primarySession.unit
        }

        id: row
        Label {
            Layout.alignment: Qt.AlignTop
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            color: row.subtle ? '#A0A0A0' : '#FFFFFF'
            font.pixelSize: 14
            font.weight: row.subtle ? 400 : 600
            text: row.title
            wrapMode: Label.WordWrap
        }
        ColumnLayout {
            Layout.alignment: Qt.AlignTop
            spacing: 2
            Label {
                Layout.alignment: Qt.AlignRight
                color: row.subtle ? '#A0A0A0' : '#FFFFFF'
                font.pixelSize: 14
                font.weight: row.subtle ? 400 : 600
                text: row_convert.output.label
            }
            Label {
                Layout.alignment: Qt.AlignRight
                color: '#A0A0A0'
                font.pixelSize: 12
                font.weight: 400
                text: '~ ' + row_convert.fiat.label
                visible: row_convert.fiat.available
            }
        }
    }

    component InvoicePaidPage: StackViewPage {
        required property string receivedLabel

        id: paid_view
        leftItem: Item {
        }
        rightItem: CloseButton {
            onClicked: paid_view.closeClicked()
        }
        contentItem: ColumnLayout {
            spacing: 12

            VSpacer {
            }
            Image {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: 96
                Layout.preferredWidth: 96
                source: 'qrc:/svg/check.svg'
            }
            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                color: '#FFFFFF'
                font.pixelSize: 24
                font.weight: 600
                horizontalAlignment: Label.AlignHCenter
                text: 'Payment received'
                wrapMode: Label.WordWrap
            }
            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                color: '#A0A0A0'
                font.pixelSize: 16
                font.weight: 400
                horizontalAlignment: Label.AlignHCenter
                text: 'You received %1.'.arg(paid_view.receivedLabel)
                wrapMode: Label.WordWrap
            }
            VSpacer {
            }
        }
    }
}
