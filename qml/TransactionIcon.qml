import Blockstream.Green
import QtQuick
import QtQuick.Layouts

import "util.js" as UtilJS

Item {
    required property string transactionType

    property var assets: []
    property int confirmations: 1
    property int maxConfirmations: 1
    property bool showProgress: false
    property color backgroundColor: '#00BCFF'

    id: self
    Layout.alignment: Qt.AlignCenter
    Layout.preferredWidth: 96
    Layout.preferredHeight: 96

    Rectangle {
        anchors.centerIn: parent
        height: 72
        width: 72
        radius: 36
        color: self.backgroundColor
        ProgressIndicator {
            anchors.fill: parent
            anchors.margins: -1
            indeterminate: self.confirmations === 0
            current: self.confirmations <= self.maxConfirmations ? self.confirmations : 0
            max: self.maxConfirmations
            visible: self.showProgress
        }
    }
    Image {
        anchors.centerIn: parent
        source: UtilJS.transactionIcon(self.transactionType, self.confirmations)
        width: 32
        height: 32
    }
    RowLayout {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        Repeater {
            model: self.assets
            delegate: AssetIcon {
                asset: modelData.asset
                border: 2
                borderColor: '#000'
            }
        }
    }
}
