import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.13
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.13

Button {
    id: self
    required property Account account
    leftInset: 0
    rightInset: 0
    topInset: 0
    bottomInset: 0
    leftPadding: 16
    rightPadding: 16
    topPadding: 16
    bottomPadding: 16
    background: Rectangle {
        border.width: 1
        border.color: '#2CCCBF'
        radius: 8
        color: self.hovered ? '#502CCCBF' : 'transparent'
    }
    contentItem: RowLayout {
        spacing: 8
        Label {
            Layout.fillWidth: true
            text: qsTrId('id_account_id')
            font.styleName: 'Regular'
        }
        Label {
            Layout.fillWidth: true
            horizontalAlignment: Label.AlignRight
            text: account.json.receiving_id
            elide: Text.ElideRight
        }
        Image {
            source: 'qrc:/svg/copy.svg'
            sourceSize.width: 16
            sourceSize.height: 16
        }
    }
    onClicked: {
        Clipboard.copy(account.json.receiving_id);
        ToolTip.show(qsTrId('id_copied_to_clipboard'), 1000);
    }
    ToolTip.delay: 300
    ToolTip.visible: hovered
    ToolTip.text: qsTrId('id_provide_this_id_to_the_asset')
}
