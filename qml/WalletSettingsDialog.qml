import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

WalletDialog {
    id: self

    width: 800
    height: 450

    background: Rectangle {
        radius: 16
        color: constants.c800
        Rectangle {
            height: parent.height
            width: side_bar.width + self.leftPadding + 16
            radius: parent.radius
            color: constants.c700
            Rectangle {
                height: parent.height
                anchors.right: parent.right
                width: parent.radius + 1
                color: constants.c700
            }
        }
    }

    header: null

    component B: Button {
        id: b
        required property int index
        Layout.fillWidth: true
        flat: true
        topPadding: 8
        bottomPadding: 8
        leftPadding: 16
        rightPadding: 16
        topInset: 0
        leftInset: 0
        rightInset: 0
        bottomInset: 0
        icon.width: 24
        icon.height: 24
        icon.color: 'white'
        highlighted: stack_layout.currentIndex === index
        onClicked: stack_layout.currentIndex = index
        background: Item {
            Rectangle {
                anchors.fill: parent
                visible: b.highlighted
                color: constants.c500
                radius: 8
            }
            Rectangle {
                anchors.fill: parent
                visible: b.hovered
                color: constants.c300
                radius: 8
            }
        }
        contentItem: RowLayout {
            spacing: 16
            Image {
                source: b.icon.source
                sourceSize.width: b.icon.width
                sourceSize.height: b.icon.height
            }
            Label {
                text: b.text
                Layout.fillWidth: true
                rightPadding: 16
                font.styleName: 'Regular'
            }
        }
    }
    component F: Flickable {
        id: flickagle
        contentWidth: width
        ScrollIndicator.vertical: ScrollIndicator {
            parent: self.background
            anchors.top: parent.top
            anchors.topMargin: self.topPadding
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: self.bottomPadding
        }
    }
    contentItem: RowLayout {
        id: layout
        spacing: 8
        ColumnLayout {
            id: side_bar
            Layout.fillWidth: false
            spacing: 8
            B {
                index: 0
                text: 'General'
                icon.source: 'qrc:/svg/preferences.svg'
            }
            B {
                index: 1
                text: 'Security'
                icon.source: 'qrc:/svg/security.svg'
            }
            B {
                index: 2
                text: 'Recovery'
                icon.source: 'qrc:/svg/recovery.svg'
            }
            Item {
                Layout.fillHeight: true
                width: 1
            }
        }
        Item {
            Layout.fillHeight: true
            width: 32
        }
        StackLayout {
            id: stack_layout
            Layout.fillWidth: true
            Layout.fillHeight: true
            F {
                contentHeight: general_view.height
                WalletGeneralSettingsView {
                    id: general_view
                    width: parent.width
                    wallet: self.wallet
                }
            }
            F {
                contentHeight: security_view.height
                WalletSecuritySettingsView {
                    id: security_view
                    width: parent.width
                    wallet: self.wallet
                }
            }
            F {
                contentHeight: recovery_view.height
                WalletRecoverySettingsView {
                    id: recovery_view
                    width: parent.width
                    wallet: self.wallet
                }
            }
        }
        ToolButton {
            Layout.alignment: Qt.AlignTop
            flat: true
            icon.source: 'qrc:/svg/cancel.svg'
            icon.width: 16
            icon.height: 16
            onClicked: self.reject()
        }
    }
}
