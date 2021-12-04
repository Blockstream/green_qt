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
    spacing: constants.s0
    Rectangle {
        height: radius * 2
        width: radius * 2
        radius: 4
        color: connected ? 'green' : connecting ? 'yellow' : 'red'
    }
    Image {
        smooth: true
        mipmap: true
        fillMode: Image.PreserveAspectFit
        horizontalAlignment: Image.AlignHCenter
        source: 'qrc:/svg/green_server.svg'
        sourceSize.height: 16
    }
    Image {
        smooth: true
        mipmap: true
        fillMode: Image.PreserveAspectFit
        horizontalAlignment: Image.AlignHCenter
        source: 'qrc:/svg/torV2.svg'
        sourceSize.height: 16
        visible: session ? session.useTor : Settings.useTor
    }
}
