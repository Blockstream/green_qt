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
        loader.sourceComponent = splash
    }

    id: self
    padding: 60
    contentItem: Loader {
        id: loader
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
