import QtQuick

QtObject {
    property bool hidden: false
    property int pointer: 0
    property var network: ({ mainnet: true, liquid: false, electrum: false })
    property string type: "p2wpkh"
    property var json: ({ satoshi: ({}) })
    property string name: ""
    property bool mainAccount: false
}
