import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS

WizardPage {
    required property Account account
    required property var dialog
    required property var transaction

    id: self
    actions: Action {
        text: qsTrId('id_ok')
        onTriggered: dialog.accept()
    }
    contentItem: ColumnLayout {
        spacing: constants.p1
        VSpacer {}
        Image {
            Layout.alignment: Qt.AlignHCenter
            source: 'qrc:/svg/check.svg'
            sourceSize.width: 64
            sourceSize.height: 64
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            id: doneLabel
            text: doneText
            font.pixelSize: 20
        }
        CopyableLabel {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: constants.p1
            font.pixelSize: 12
            delay: 50
            text: self.transaction.data.txhash
            onCopy: Analytics.recordEvent('share_transaction', AnalyticsJS.segmentationShareTransaction(self.account))
        }
        VSpacer {}
    }
}
