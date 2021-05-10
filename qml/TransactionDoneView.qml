import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.12
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

WizardPage {
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
        }
        VSpacer {}
    }
}
