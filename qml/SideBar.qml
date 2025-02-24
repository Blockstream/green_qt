﻿import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Pane {
    enum View {
        Blockstream,
        Wallets,
        Preferences
    }

    signal blockstreamClicked
    signal preferencesClicked
    signal walletsClicked
    signal crashClicked

    property int currentView: SideBar.Wallets

    id: self
    focusPolicy: Qt.ClickFocus
    topPadding: 30
    bottomPadding: 30
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

    contentItem: ColumnLayout {
        Image {
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 20
            Layout.bottomMargin: 20
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            source: 'qrc:/svg/home.svg'
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
        VSpacer {
        }
        SideButton {
            visible: Qt.application.arguments.indexOf('--debug') > 0
            icon.source: 'qrc:/svg2/bug.svg'
            text: 'Crash'
            onClicked: self.crashClicked()
        }
        SideButton {
            icon.source: 'qrc:/svg2/gear.svg'
            isCurrent: self.currentView === SideBar.View.Preferences
            onClicked: self.preferencesClicked()
            text: qsTrId('id_app_settings')
        }
    }
}
