import Blockstream.Green
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

Page {
    required property Account account
    property alias model: list_view.model
    property alias label: label

    focusPolicy: Qt.ClickFocus
    id: self
    background: null
    spacing: constants.p1
    header: GHeader {
        Label {
            id: label
            text: qsTrId('id_assets')
            font.pixelSize: 20
            font.styleName: 'Bold'
        }
        HSpacer {
        }
    }
    contentItem: GListView {
        id: list_view
        clip: true
        model: self.account.balances
        spacing: 0
        implicitHeight: contentHeight
        delegate: AssetDelegate {
            balance: modelData
            width: ListView.view.contentWidth
            onClicked: if (hasDetails) balance_dialog.createObject(window, { balance }).open()
        }
    }

    Component {
        id: balance_dialog
        AssetView {
        }
    }
}
