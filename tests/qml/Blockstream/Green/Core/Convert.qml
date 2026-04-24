import QtQuick

QtObject {
    property var context
    property var account
    property var asset
    property var input: ({})
    property string unit: "btc"
    property var output: ({ label: ((input?.satoshi ?? 0).toString() + " " + unit) })
    property var fiat: ({ label: "USD", available: true })
}
