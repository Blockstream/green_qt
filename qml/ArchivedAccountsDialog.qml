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
                id: list_view
                onCountChanged: if (count === 0) self.close()
                currentIndex: 0
                spacing: 5
                model: archive_list_model
                delegate: AccountDelegate {
                    id: delegate
                    onClicked: list_view.currentIndex = delegate.index
                }
            }
        }
    }
}
