import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.12

RowLayout {
    required property Session session
    readonly property bool connected: session && session.active && session.connected
    readonly property bool connecting: session && session.active && !session.connected

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
            progress: connected ? 1 : 0
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
                progress: {
                    if (connected) return 1
                    if (session && session.event.tor) return session.event.tor.progress * 0.01
                    return 0
                }
                opacity: connecting && progress < 1? 1 : 0
            }
        }
    }
    Loader {
        active: session && session.network.electrum
        visible: active
        sourceComponent: RowLayout {
            Image {
                smooth: true
                mipmap: true
                fillMode: Image.PreserveAspectFit
                horizontalAlignment: Image.AlignHCenter
                source: 'qrc:/svg/electrum.svg'
                sourceSize.height: 16
            }
            Label {
                text: session.usePersonalNode ? session.electrumUrl : session.network.data.electrum_url
                font.pixelSize: 12
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
