import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

AbstractDrawer {
    required property Context context

    Connections {
        target: self.context
        function onAutoLogout() {
            self.close()
        }
    }

    id: self
    edge: Qt.RightEdge
    minimumContentWidth: 350
    contentItem: GStackView {
        id: stack_view
        initialItem: StatusPage {
        }
    }

    onClosed: stack_view.pop(stack_view.initialItem)

    component StatusPage: StackViewPage {
        id: page
        title: qsTrId('id_status')
        rightItem: CloseButton {
            onClicked: self.closeClicked()
        }
        contentItem: ColumnLayout {
            spacing: 8
            AbstractButton {
                Layout.fillWidth: true
                font.pixelSize: 14
                font.weight: 500
                leftPadding: 20
                rightPadding: 20
                topPadding: 20
                bottomPadding: 20
                visible: self.context.primarySession.useTor
                background: Rectangle {
                    color: '#222226'
                    radius: 5
                }
                contentItem: RowLayout {
                    Image {
                        Layout.alignment: Qt.AlignCenter
                        Layout.preferredHeight: 24
                        Layout.preferredWidth: 24
                        Layout.rightMargin: 10
                        source: 'qrc:/svg/torV2.svg'
                    }
                    Label {
                        Layout.fillWidth: true
                        text: qsTrId('id_connect_with_tor')
                    }
                }
            }
            AbstractButton {
                Layout.fillWidth: true
                font.pixelSize: 14
                font.weight: 500
                leftPadding: 20
                rightPadding: 20
                topPadding: 20
                bottomPadding: 20
                visible: self.context.primarySession.useProxy
                background: Rectangle {
                    color: '#222226'
                    radius: 5
                }
                contentItem: RowLayout {
                    Image {
                        Layout.alignment: Qt.AlignCenter
                        Layout.preferredHeight: 24
                        Layout.preferredWidth: 24
                        Layout.rightMargin: 10
                        source: 'qrc:/svg/proxyV2.svg'
                    }
                    ColumnLayout {
                        Label {
                            Layout.fillWidth: true
                            text: qsTrId('id_connect_through_a_proxy')
                        }
                        Label {
                            Layout.fillWidth: true
                            opacity: 0.6
                            text: self.context.primarySession.proxy
                        }
                    }
                }
            }
            SectionLabel {
                Layout.topMargin: 10
                text: qsTrId('id_networks')
            }
            Repeater {
                model: self.context.sessions
                delegate: SessionButton {
                    required property var modelData
                    id: delegate
                    session: modelData
                    onClicked: page.StackView.view.push(session_page, { session: delegate.session })
                }
            }
            VSpacer {
            }
        }
    }

    component SessionButton: AbstractButton {
        required property Session session
        Layout.fillWidth: true
        id: button
        font.pixelSize: 14
        font.weight: 500
        leftPadding: 20
        rightPadding: 20
        topPadding: 20
        bottomPadding: 20
        opacity: button.enabled ? 1 : 0.6
        background: Rectangle {
            color: '#222226'
            radius: 5
        }
        contentItem: RowLayout {
            spacing: 20
            Image {
                Layout.alignment: Qt.AlignCenter
                Layout.preferredHeight: 24
                Layout.preferredWidth: 24
                source: UtilJS.iconFor(button.session.network)
            }
            ColumnLayout {
                Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    text: button.session.network.displayName + ' ' + (button.session.network.electrum ? qsTrId('id_singlesig') : qsTrId('id_multisig'))
                    wrapMode: Label.Wrap
                }
                Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    opacity: 0.6
                    font.pixelSize: 10
                    text: {
                        if (button.session.usePersonalNode) {
                            return button.session.electrumUrl
                        }
                        const network = button.session.network
                        let url
                        if (button.session.useTor) {
                            url = network.electrum ? network.data.electrum_onion_url : network.data.wamp_onion_url
                        } else {
                            url = network.electrum ? network.data.electrum_url : network.data.wamp_url
                        }
                        try {
                            let hostname = new URL(url).hostname
                            if (!hostname) hostname = new URL('http://' + url).hostname
                            return hostname
                        } catch (e) {
                            return url
                        }
                    }
                    wrapMode: Label.WrapAnywhere
                }
            }
            Rectangle {
                Layout.margins: 10
                Layout.alignment: Qt.AlignCenter
                implicitHeight: 8
                implicitWidth: 8
                radius: 4
                color: button.session.connected ? '#00FF00' : '#FF0000'
            }
        }
    }
}
