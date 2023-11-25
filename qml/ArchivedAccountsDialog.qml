import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

WalletDialog {
    id: self
    header: null
    width: 450
    height: 600
    contentItem: GStackView {
        initialItem: StackViewPage {
            title: qsTrId('id_archived_accounts')
            rightItem: CloseButton {
                onClicked: self.close()
            }
            contentItem: TListView {
                onCountChanged: if (count === 0) self.close()
                currentIndex: 0
                spacing: 3
                model: archive_list_model
                delegate: Component {
                    AccountDelegate {
                    }
                }
            }
        }
    }
}
