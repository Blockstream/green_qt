import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts

import "util.js" as UtilJS

MainPage {
    signal timeout()
    Component.onCompleted: {
        if (WalletManager.wallets.length === 0) {
            Settings.registerEvent({ type: 'rebrand_notice' })
            loader.sourceComponent = splash
        } else if (!Settings.isEventRegistered({ type: 'rebrand_notice' })) {
            loader.sourceComponent = rebrand
        } else {
            loader.sourceComponent = splash
        }
    }

    id: self
    padding: 60
    contentItem: Loader {
        id: loader
    }

    Component {
        id: rebrand
        ColumnLayout {
            spacing: 10
            VSpacer {
            }
            Image {
                Layout.alignment: Qt.AlignCenter
                source: 'qrc:/svg2/green-rebrand.svg'
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                Layout.topMargin: 50
                color: '#FFF'
                font.pixelSize: 30
                font.weight: 656
                horizontalAlignment: Label.AlignHCenter
                text: 'Green is now the Blockstream App'
            }
            LinkLabel {
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true
                Layout.maximumWidth: 500
                Layout.preferredWidth: 0
                font.pixelSize: 14
                font.weight: 400
                horizontalAlignment: Label.AlignHCenter
                text: `All your settings and funds are safe and exactly where you left them.<br/>Your app icon will update in upcoming releases, and remember: our only official website is ${UtilJS.link('https://blockstream.com', qsTrId('blockstream.com'))}. Stay vigilant against scams!`
                wrapMode: Label.Wrap
            }
            CheckBox {
                Layout.alignment: Qt.AlignCenter
                Layout.topMargin: 20
                id: checkbox
                text: qsTrId('id_dont_show_this_again')
            }
            PrimaryButton {
                Layout.alignment: Qt.AlignCenter
                Layout.minimumWidth: 200
                focus: true
                text: qsTrId('id_continue')
                onClicked: {
                    if (checkbox.checked) {
                        Settings.registerEvent({ type: 'rebrand_notice' })
                    }
                    self.timeout()
                }
            }
            VSpacer {
            }
        }
    }

    Component {
        id: splash
        ColumnLayout {
            Timer {
                running: true
                interval: 1500
                onTriggered: self.timeout()
            }
            spacing: 10
            VSpacer {
            }
            Image {
                Layout.alignment: Qt.AlignCenter
                source: 'qrc:/svg2/blockstream-app.svg'
                layer.enabled: true
                layer.effect: MultiEffect {
                    autoPaddingEnabled: true
                    blurEnabled: true
                    blurMax: 64
                    NumberAnimation on blur {
                        easing.type: Easing.OutCubic
                        from: 1
                        to: 0
                        duration: 300
                    }
                }
                NumberAnimation on scale {
                    easing.type: Easing.OutCubic
                    from: 1.1
                    to: 1
                    duration: 300
                }
                NumberAnimation on opacity {
                    easing.type: Easing.OutCubic
                    from: 0
                    to: 1
                    duration: 300
                }
            }
            VSpacer {
            }
        }
    }
}
