import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    required property Session session
    readonly property bool connected: session?.connected ?? false
    readonly property bool connecting: session?.connecting ?? false

    Layout.fillWidth: false
    spacing: 12
    opacity: (connecting || connected) ? 1 : 0.5

    Image {
        smooth: true
        mipmap: true
        fillMode: Image.PreserveAspectFit
        horizontalAlignment: Image.AlignHCenter
        source: 'qrc:/svg/green_server.svg'
        sourceSize.height: 16
        ProgressIndicator {
            anchors.fill: parent
            anchors.margins: -4
            indeterminate: connecting
            current: connected ? 1 : 0
            max: 1
            opacity: connecting && progress < 1 ? 1 : 0
        }
    }
    Loader {
        active: session ? session.useTor : Settings.useTor
        visible: active
        sourceComponent: Image {
            smooth: true
            mipmap: true
            fillMode: Image.PreserveAspectFit
            horizontalAlignment: Image.AlignHCenter
            source: 'qrc:/svg/torV2.svg'
            sourceSize.height: 16
            ProgressIndicator {
                anchors.fill: parent
                anchors.margins: -4
                indeterminate: connecting && progress === 0
                current: {
                    if (connected) return 100
                    if (session && session.events.tor) return session.events.tor.progress
                    return 0
                }
                max: 100
                opacity: connecting && progress < 1 ? 1 : 0
            }
        }
    }
    Loader {
        active: session && session.network.electrum
        visible: active
        sourceComponent: Image {
            smooth: true
            mipmap: true
            fillMode: Image.PreserveAspectFit
            horizontalAlignment: Image.AlignHCenter
            source: 'qrc:/svg/electrum.svg'
            sourceSize.height: 16
            ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
            ToolTip.text: session.usePersonalNode ? session.electrumUrl : session.network.data.electrum_url
            ToolTip.visible: hover_handler.hovered
            HoverHandler {
                id: hover_handler
            }
        }
    }
    Loader {
        active: session && session.enableSPV
        visible: active
        sourceComponent: Image {
            smooth: true
            mipmap: true
            fillMode: Image.PreserveAspectFit
            horizontalAlignment: Image.AlignHCenter
            source: 'qrc:/svg/tx-check.svg'
            sourceSize.height: 16
        }
    }
}
