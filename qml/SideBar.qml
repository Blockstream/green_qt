import Blockstream.Green
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

    signal preferencesClicked
    signal walletsClicked
    signal crashClicked

    property WalletView currentWalletView
    property int currentView: SideBar.Wallets
    property real maximumWidth: 250
    readonly property real position: (width - self.implicitWidth) / (self.maximumWidth - self.implicitWidth)
    Behavior on width {
        enabled: !drag_handler.active
        SmoothedAnimation {
            id: width_animation
            velocity: 500
        }
    }


    id: self
    focusPolicy: Qt.ClickFocus
    topPadding: 30
    bottomPadding: 30
    leftPadding: 0
    rightPadding: 0
    background: Rectangle {
        color: '#181818'
        Rectangle {
            width: 1
            anchors.right: parent.right
            height: parent.height
            color: '#262626'
        }
        HoverHandler {
            cursorShape: Qt.SizeHorCursor
        }
        DragHandler {
            property real startWidth
            id: drag_handler
            dragThreshold: 1
            target: null
            enabled: !width_animation.running
            margin: 24
            onActiveChanged: {
                if (drag_handler.active) {
                    drag_handler.startWidth = self.width
                    self.width = Qt.binding(() => Math.max(self.implicitWidth, Math.min(self.maximumWidth, drag_handler.startWidth + drag_handler.xAxis.activeValue)))
                } else {
                    if (self.width - 100 < self.implicitWidth) {
                        Qt.callLater(() => { self.width = Qt.binding(() => self.implicitWidth) })
                    } else if (self.width + 100 > self.maximumWidth) {
                        Qt.callLater(() => { self.width = self.maximumWidth })
                    } else {
                        Qt.callLater(() => { self.width = drag_handler.startWidth })
                    }
                }
            }
        }
    }
    contentItem: ColumnLayout {
        spacing: 0
        Logo {
        }
        SideButton {
            icon.source: 'qrc:/svg/menu-home.svg'
            text: qsTrId('id_home')
            visible: self.currentWalletView?.wallet?.context ?? false
        }
        SideButton {
            icon.source: 'qrc:/svg/menu-transactions.svg'
            text: qsTrId('id_transactions')
            visible: self.currentWalletView?.wallet?.context ?? false
        }
        SideButton {
            icon.source: 'qrc:/svg/menu-security.svg'
            text: qsTrId('id_security')
            visible: self.currentWalletView?.wallet?.context ?? false
        }
        SideButton {
            icon.source: 'qrc:/svg/menu-settings.svg'
            text: qsTrId('id_settings')
            visible: self.currentWalletView?.wallet?.context ?? false
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
            icon.source: 'qrc:/svg/menu-wallet.svg'
            isCurrent: self.currentView === SideBar.View.Wallets
            onClicked: self.walletsClicked()
            text: qsTrId('id_wallets')
        }
        SideButton {
            icon.source: 'qrc:/svg2/gear.svg'
            isCurrent: self.currentView === SideBar.View.Preferences
            onClicked: self.preferencesClicked()
            text: qsTrId('id_app_settings')
        }
    }

    component Logo: Pane {
        Layout.bottomMargin: 40
        Layout.fillWidth: true
        background: null
        clip: true
        padding: 0
        contentItem: RowLayout {
            spacing: 0
            HSpacer {
                Layout.preferredWidth: 0
                Layout.maximumWidth: 36
            }
            Image {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                source: 'qrc:/svg/home.svg'
            }
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                opacity: self.position
                Image {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    source: 'qrc:/svg/blockstream'
                }
            }
        }
    }

    component SideButton: AbstractButton {
        property bool isCurrent: false
        Layout.bottomMargin: 10
        Layout.fillWidth: true
        id: button
        clip: true
        bottomPadding: 12
        leftPadding: 24
        rightPadding: 24
        topPadding: 12
        background: Item {
            Rectangle {
                radius: 8 * self.position
                color: 'white'
                opacity: button.hovered ? 0.1 : 0
                Behavior on opacity {
                    SmoothedAnimation {
                        velocity: 1
                    }
                }
                x: 24 * self.position
                width: parent.width
                height: parent.height
            }
            Rectangle {
                color: 'transparent'
                radius: 8 * self.position
                border.width: 2
                border.color: '#00BCFF'
                visible: button.visualFocus
                x: 24 * self.position
                width: parent.width
                height: parent.height
            }
            Rectangle {
                color: '#00BCFF'
                visible: button.visualFocus || button.isCurrent
                x: parent.width - 2
                width: 2
                height: parent.height
            }
        }
        contentItem: RowLayout {
            spacing: 0
            HSpacer {
                Layout.maximumWidth: 12
            }
            Image {
                source: button.icon.source
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                id: label
                color: '#A0A0A0'
                font.pixelSize: 16
                font.weight: 600
                leftPadding: 12
                opacity: self.position
                text: button.text
                wrapMode: Label.NoWrap
            }
        }
    }
}
