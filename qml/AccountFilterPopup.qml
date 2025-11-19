import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

FilterPopup {
    required property Context context
    required property ContextModel model
    property var filterAccounts
    property var accounts
    Component.onCompleted: {
        self.filterAccounts = [...self.model.filterAccounts]
        self.accounts = [...self.context.accounts].filter(account => !account.hidden && self.filterAccounts.indexOf(account) < 0)
    }
    id: self
    height: Math.min(self.implicitHeight, 600)
    Repeater {
        model: self.filterAccounts
        delegate: Delegate {
            required property var modelData
            Layout.bottomMargin: 4
            Layout.topMargin: 4
            Layout.minimumWidth: 350
            Layout.fillWidth: true
            id: delegate
            account: delegate.modelData
            opacity: 1
        }
    }
    FilterPopup.Separator {
        visible: self.filterAccounts.length > 0 && self.accounts.length > 0
    }
    Repeater {
        model: self.accounts
        delegate: Delegate {
            required property var modelData
            Layout.bottomMargin: 4
            Layout.topMargin: 4
            Layout.minimumWidth: 350
            Layout.fillWidth: true
            id: delegate
            account: delegate.modelData
            opacity: 1
        }
    }

    component Delegate: ItemDelegate {
        signal accountClicked(Account account)
        required property Account account
        onClicked: {
            const filter = self.model.filterAccounts.indexOf(delegate.account) < 0
            self.model.updateFilterAccounts(delegate.account, filter)
        }
        id: delegate
        focusPolicy: Qt.ClickFocus
        background: Rectangle {
            color: UtilJS.networkColor(delegate.account.network)
            clip: true
            radius: 5
        }
        leftPadding: 12
        rightPadding: 12
        topPadding: 8
        bottomPadding: 8
        layer.enabled: true
        contentItem: RowLayout {
            ColumnLayout {
                Layout.bottomMargin: 6
                spacing: 0
                Label {
                    font.pixelSize: 10
                    font.weight: 400
                    font.styleName: 'Regular'
                    font.capitalization: Font.AllUppercase
                    color: 'white'
                    text: UtilJS.networkLabel(delegate.account.network) + ' / ' + UtilJS.accountLabel(delegate.account)
                    elide: Label.ElideLeft
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                }
                Label {
                    Layout.fillWidth: true
                    font.pixelSize: 16
                    font.weight: 600
                    text: UtilJS.accountName(account)
                }
            }
            Image {
                Layout.alignment: Qt.AlignCenter
                source: 'qrc:/svg2/check.svg'
                opacity: self.model.filterAccounts.indexOf(delegate.account) >= 0 ? 1 : 0
            }
        }
    }
}
