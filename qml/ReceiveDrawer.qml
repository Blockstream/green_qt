import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

WalletDrawer {
    required property Account account
    property Asset asset

    ReceiveAddressController {
        id: controller
        account: self.account
        amount: '10'
    }

    id: self
    width: 500
    contentItem: GStackView {
        id: stack_view
        initialItem: Page {
            background: null
            header: Pane {
                background: null
                padding: 0
                bottomPadding: 20
                contentItem: RowLayout {
                    Label {
                        font.family: 'SF Compact Display'
                        font.pixelSize: 20
                        font.weight: 790
                        text: qsTrId('id_receive')
                    }
                    HSpacer {
                    }
                    CloseButton {
                        onClicked: self.close()
                    }
                }
            }
            contentItem: ColumnLayout {
                spacing: 5
                Label {
                    font.family: 'SF Compact Display'
                    font.pixelSize: 14
                    font.weight: 600
                    opacity: 0.4
                    text: 'Asset & Account'
                }
                AbstractButton {
                    Layout.fillWidth: true
                    padding: 20
                    background: Rectangle {
                        radius: 5
                        color: '#222226'
                    }
                    contentItem: RowLayout {
                        spacing: 10
                        Image {
                            Layout.alignment: Qt.AlignCenter
                            Layout.maximumWidth: 32
                            Layout.maximumHeight: 32
                            source: UtilJS.iconFor(self.asset || self.account)
                        }
                        ColumnLayout {
                            Layout.alignment: Qt.AlignCenter
                            Layout.fillWidth: false
                            Layout.fillHeight: false
                            spacing: 0
                            Label {
                                font.family: 'SF Compact Display'
                                font.pixelSize: 16
                                font.weight: 600
                                text: self.asset?.name ?? self.account.network.displayName
                            }
                            Item {
                                Layout.minimumHeight: 4
                            }
                            Label {
                                font.capitalization: Font.AllUppercase
                                font.family: 'SF Compact Display'
                                font.pixelSize: 12
                                font.weight: 500
                                opacity: 0.4
                                text: self.account.name
                            }
                            Label {
                                font.capitalization: Font.AllUppercase
                                font.family: 'SF Compact Display'
                                font.pixelSize: 11
                                font.weight: 400
                                opacity: 0.4
                                text: UtilJS.networkLabel(self.account.network) + ' / ' + UtilJS.accountLabel(self.account)
                            }
                        }
                        HSpacer {
                        }
                        Image {
                            Layout.alignment: Qt.AlignCenter
                            source: 'qrc:/svg2/edit.svg'
                        }
                    }
                    onClicked: stack_view.push(asset_account_selector)
                }
                Item {
                    Layout.minimumHeight: 25
                }
                Label {
                    font.family: 'SF Compact Display'
                    font.pixelSize: 14
                    font.weight: 600
                    opacity: 0.4
                    text: 'Account Address'
                }
                Pane {
                    Layout.fillWidth: true
                    padding: 20
                    background: Rectangle {
                        radius: 5
                        color: '#222226'
                    }
                    contentItem: ColumnLayout {
                        spacing: 10
                        Image {
                            Layout.alignment: Qt.AlignRight
                            source: 'qrc:/svg2/refresh.svg'
                            TapHandler {
                                onTapped: controller.generate()
                            }
                        }
                        QRCode {
                            Layout.alignment: Qt.AlignHCenter
                            id: qrcode
                            text: controller.uri
                            implicitHeight: 200
                            implicitWidth: 200
                            radius: 4
                        }
                        Label {
                            Layout.fillWidth: true
                            font.family: 'SF Compact Display'
                            font.pixelSize: 12
                            font.weight: 500
                            horizontalAlignment: Label.AlignHCenter
                            text: controller.uri
                            wrapMode: Label.WrapAnywhere
                        }
                        CopyAddressButton {
                            Layout.alignment: Qt.AlignCenter
                        }
                    }
                }

                VSpacer {
                }
                RowLayout {
                    spacing: 26
                    AbstractButton {
                        Layout.fillWidth: true
                        padding: 16
                        background: Rectangle {
                            radius: 8
                            border.width: 1
                            border.color: '#FFF'
                            color: 'transparent'
                        }
                        contentItem: RowLayout {
                            Label {
                                Layout.alignment: Qt.AlignCenter
                                font.family: 'SF Compact Display'
                                font.pixelSize: 16
                                font.weight: 700
                                text: 'More Options'
                            }
                        }
                    }
                    AbstractButton {
                        Layout.fillWidth: true
                        padding: 16
                        background: Rectangle {
                            radius: 8
                            color: '#00B45A'
                        }
                        contentItem: RowLayout {
                            Label {
                                Layout.alignment: Qt.AlignCenter
                                font.family: 'SF Compact Display'
                                font.pixelSize: 16
                                font.weight: 700
                                text: 'Share'
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: asset_account_selector
        AssetAccountSelector {
        }
    }

    component AssetAccountSelector: Page {
        background: null
        header: Pane {
            background: null
            padding: 0
            bottomPadding: 20
            contentItem: RowLayout {
                BackButton {
                    Layout.minimumWidth: Math.max(left_item.implicitWidth, right_item.implicitWidth)
                    id: left_item
                    onClicked: stack_view.pop()
                }
                HSpacer {
                }
                Label {
                    font.family: 'SF Compact Display'
                    font.pixelSize: 14
                    font.weight: 600
                    text: qsTrId('Choose Asset')
                }
                HSpacer {
                }
                Item {
                    Layout.minimumWidth: Math.max(left_item.implicitWidth, right_item.implicitWidth)
                    id: right_item
                }
            }
        }
        contentItem: ColumnLayout {
            spacing: 5
            TextField {
                id: search_field
                Layout.fillWidth: true
                leftPadding: 20
                rightPadding: 40 + search_image.width
                topPadding: 20
                bottomPadding: 20
                placeholderText: 'Search Asset'
                placeholderTextColor: Qt.rgba(1, 1, 1, 0.4)
                background: Rectangle {
                    radius: 4
                    color: '#2F2F35'
                    Image {
                        id: search_image
                        source: 'qrc:/svg2/search.svg'
                        anchors.margins: 20
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                    }
                }
            }
            Item {
                Layout.minimumHeight: 25
            }
            Label {
                font.family: 'SF Compact Display'
                font.pixelSize: 14
                font.weight: 600
                opacity: 0.4
                text: search_field.text.trim().length > 0 ? 'Search result' : 'Other Assets'
            }
            GListView {
                id: list_view
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: -1
                clip: true
                model: AssetsModel {
//                    context: self.context
                    filter: search_field.text.trim()
                    minWeight: 1
                }
                spacing: 4
                delegate: ItemDelegate {
                    required property Asset asset
                    required property int index
                    id: delegate
                    width: ListView.view.contentWidth
                    padding: 0
                    topPadding: 0
                    bottomPadding: 0
                    topInset: 0
                    bottomInset: 0
                    background: Rectangle {
                        radius: 4
                        color: '#2F2F35'
                        border.width: delegate.ListView.isCurrentItem ? 2 : 0
                        border.color: '#00B45A'
                    }
                    contentItem: ColumnLayout {
                        spacing: 0
                        AbstractButton {
                            Layout.fillWidth: true
                            background: null
                            padding: 10
                            contentItem: RowLayout {
                                spacing: 10
                                AssetIcon {
                                    asset: delegate.asset
                                }
                                Label {
                                    Layout.fillWidth: true
                                    font.family: 'SF Compact Display'
                                    font.pixelSize: 14
                                    font.weight: 500
                                    text: delegate.asset.name
                                    elide: Label.ElideMiddle
                                }
                            }
                            onClicked: list_view.currentIndex = delegate.ListView.isCurrentItem ? -1 : delegate.index
                        }
                        Collapsible {
                            Layout.fillWidth: true
                            collapsed: !delegate.ListView.isCurrentItem
                            contentWidth: width
                            contentHeight: collapsible_layout.height
                            ColumnLayout {
                                id: collapsible_layout
                                width: parent.width
                                spacing: 0
                                Pane {
                                    Layout.fillWidth: true
                                    padding: 10
                                    visible: delegate.asset.amp
                                    background: Rectangle {
                                        color: '#00B45A'
                                        opacity: 0.2
                                    }
                                    contentItem: RowLayout {
                                        spacing: 10
                                        Image {
                                            Layout.alignment: Qt.AlignCenter
                                            source: 'qrc:/svg2/shield_warning.svg'
                                        }
                                        Label {
                                            Layout.preferredWidth: 0
                                            Layout.fillWidth: true
                                            color: '#00B45A'
                                            font.family: 'SF Compact Display'
                                            font.pixelSize: 12
                                            font.weight: 600
                                            text: `${delegate.asset.name} is an AMP asset. You need an AMP account in order to receive it.`
                                            wrapMode: Label.WordWrap
                                        }
                                    }
                                }
                                Rectangle {
                                    width: parent.width
                                    height: 2
                                    color: delegate.ListView.isCurrentItem ? '#00B45A' : 'transparent'
                                }
                                Label {
                                    visible: false
                                    Layout.fillWidth: true
                                    wrapMode: Label.WordWrap
                                    text: JSON.stringify(delegate.asset.data, null, '  ')
                                }
                                Repeater {
                                    model: self.context.accounts
                                    delegate: AbstractButton {
                                        readonly property Account account: modelData
                                        Layout.fillWidth: true
                                        id: account_button
                                        background: Item {
                                            Rectangle {
                                                color: '#FFF'
                                                opacity: 0.2
                                                width: parent.width
                                                height: 1
                                                anchors.bottom: parent.bottom
                                            }
                                        }
                                        padding: 10
                                        contentItem: RowLayout {
                                            ColumnLayout {
                                                Label {
                                                    Layout.alignment: Qt.AlignCenter
                                                    font.family: 'SF Compact Display'
                                                    font.pixelSize: 14
                                                    font.weight: 500
                                                    text: account_button.account.name
                                                }
                                                Label {
                                                    font.family: 'SF Compact Display'
                                                    font.pixelSize: 11
                                                    font.weight: 400
                                                    opacity: 0.4
                                                    text: UtilJS.networkLabel(account_button.account.network) + ' / ' + UtilJS.accountLabel(account_button.account)
                                                }
                                            }
                                            HSpacer {
                                            }
                                            Image {
                                                Layout.alignment: Qt.AlignCenter
                                                source: 'qrc:/svg2/next_arrow.svg'
                                            }
                                        }
                                        onClicked: {
                                            self.account = account_button.account
                                            self.asset = delegate.asset
                                            stack_view.pop()
                                        }
                                    }
                                }
                                AbstractButton {
                                    Layout.fillWidth: true
                                    background: null
                                    padding: 10
                                    contentItem: RowLayout {
                                        Label {
                                            Layout.alignment: Qt.AlignCenter
                                            font.family: 'SF Compact Display'
                                            font.pixelSize: 14
                                            font.weight: 500
                                            text: 'Create New Account'
                                        }
                                        HSpacer {
                                        }
                                        Image {
                                            Layout.alignment: Qt.AlignCenter
                                            source: 'qrc:/svg2/next_arrow.svg'
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    component CopyAddressButton: AbstractButton {
        padding: 10
        Timer {
            id: timer
            repeat: false
            interval: 1000
        }

        background: Rectangle {
            color: '#13161D'
            radius: 4
        }
        contentItem: RowLayout {
            spacing: 10
            Item {
                Layout.minimumHeight: 22
                Layout.minimumWidth: 22
                Image {
                    anchors.centerIn: parent
                    source: timer.running ? 'qrc:/svg2/check.svg' : 'qrc:/svg2/copy.svg'
                }
            }
            Label {
                font.family: 'SF Compact Display'
                font.pixelSize: 12
                font.weight: 600
                text: 'Copy Address'
            }
        }
        onClicked: {
            Clipboard.copy(controller.uri)
            timer.restart()
        }
    }
}
