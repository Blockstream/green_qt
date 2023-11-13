import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Pane {
    enum View {
        Home,
        Blockstream,
        Wallets,
        Preferences
    }

    signal homeClicked
    signal blockstreamClicked
    signal preferencesClicked
    signal walletsClicked

    property int currentView: -1

    id: self
    focusPolicy: Qt.ClickFocus
    topPadding: 0
    bottomPadding: 0
    leftPadding: 0
    rightPadding: 0
    background: Rectangle {
        color: '#13161D'
        Rectangle {
            width: 1
            anchors.right: parent.right
            height: parent.height
            color: Qt.rgba(0, 0, 0, 0.5)
        }
    }
    implicitWidth: 72
    Behavior on implicitWidth {
        NumberAnimation {
            duration: 300
            easing.type: Easing.InOutCubic
        }
    }

    contentItem: ColumnLayout {
        spacing: 10
        Item {
            Layout.minimumHeight: 20
        }
        SideButton {
            enabled: true
            icon.source: 'qrc:/svg/home.svg'
            isCurrent: self.currentView === SideBar.View.Home
            onClicked: self.homeClicked()
            text: qsTrId('id_home')
            visible: false
        }
        SideButton {
            icon.source: 'qrc:/svg/blockstream-logo.svg'
            isCurrent: self.currentView === SideBar.View.Blockstream
            onClicked: self.blockstreamClicked()
            text: 'Blockstream News'
            visible: false // Settings.showNews
        }
        SideButton {
            icon.source: 'qrc:/svg2/wallet.svg'
            isCurrent: self.currentView === SideBar.View.Wallets
            onClicked: self.walletsClicked()
            text: qsTrId('id_wallets')
        }
        SideButton {
            icon.source: 'qrc:/svg/jade_emblem_on_transparent_rgb.svg'
            text: 'Blockstream Jade'
            visible: false
        }
        SideButton {
            icon.source: 'qrc:/svg/ledger-logo.svg'
            text: 'Ledger Nano'
            visible: false
        }
        VSpacer {
        }
        SideButton {
            icon.source: 'qrc:/svg2/gear.svg'
            isCurrent: self.currentView === SideBar.View.Preferences
            onClicked: self.preferencesClicked()
            text: qsTrId('id_app_settings')
            icon.width: 24
            icon.height: 24
        }
    }
}
