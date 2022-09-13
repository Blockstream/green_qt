import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.13

AbstractDialog {
    id: self
    title: 'Help improve Green'
    modal: false
    showRejectButton: true
    closePolicy: Dialog.NoAutoClose
    height: layout.implicitHeight + self.implicitFooterHeight + self.implicitHeaderHeight + self.topPadding + self.bottomPadding + self.spacing
    width: layout.implicitWidth + self.leftPadding + self.rightPadding
    anchors.centerIn: undefined

    ColumnLayout {
        id: layout
        spacing: constants.s2
        Layout.maximumWidth: 420
        Label {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            text: 'If you agree, Green will collect anonymous data to optimize the user experience. No individual user or wallet can be identified.'
            wrapMode: Label.WordWrap
        }
        Pane {
            id: pane
            spacing: 0
            padding: constants.p2
            Layout.fillWidth: true
            Layout.maximumHeight: padding * 2 + implicitContentHeight
            background: Rectangle {
                color: constants.c500
                radius: 8
                MouseArea {
                    anchors.fill: parent
                    onClicked: collapsible.toggle()
                }
                Rectangle {
                    implicitHeight: 1
                    color: constants.c800
                    y: pane.padding * 2 + details_label.height
                    width: parent.width
                }
            }
            contentItem: ColumnLayout {
                spacing: 0
                Label {
                    id: details_label
                    Layout.fillWidth: true
                    text: collapsible.collapsed ? qsTrId('Show details') : qsTrId('Hide details')
                    Image {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        fillMode: Image.PreserveAspectFit
                        sourceSize.height: 16
                        sourceSize.width: 16
                        source: 'qrc:/svg/down.svg'
                        transformOrigin: Item.Center
                        rotation: collapsible.collapsed ? 180 : 0
                        Behavior on rotation {
                            RotationAnimation {
                                duration: 400
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }
                Collapsible {
                    Layout.maximumWidth: 420
                    Layout.maximumHeight: implicitHeight
                    id: collapsible
                    contentHeight: details_layout.height
                    contentWidth: 420
                    collapsed: true
                    ColumnLayout {
                        id: details_layout
                        spacing: constants.s1
                        Label {
                            Layout.maximumWidth: 420
                            topPadding: constants.p3 + constants.p2
                            font.bold: true
                            text: "What's collected"
                        }
                        Label {
                            Layout.maximumWidth: 420
                            text: "• Page visits, button presses, general application configurations"
                            wrapMode: Label.WordWrap
                        }
                        Label {
                            Layout.maximumWidth: 420
                            text: "• Operative System and application version, loading times, crashes"
                            wrapMode: Label.WordWrap
                        }
                        Label {
                            Layout.maximumWidth: 420
                            topPadding: constants.p2
                            font.bold: true
                            text: "What's NOT collected"
                        }
                        Label {
                            Layout.maximumWidth: 420
                            text: "• Recovery phrases, key material, addresses"
                            wrapMode: Label.WordWrap
                        }
                        Label {
                            Layout.maximumWidth: 420
                            text: "• User contact info, IP address, location"
                            wrapMode: Label.WordWrap
                        }
                        Label {
                            Layout.maximumWidth: 420
                            textFormat: Text.RichText
                            onLinkActivated: Qt.openUrlExternally(link)
                            text: link('https://help.blockstream.com/hc/en-us/articles/5988514431897', qsTrId('Learn more'))
                            background: MouseArea {
                                acceptedButtons: Qt.NoButton
                                cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                            }
                        }
                    }
                }
            }
        }
    }
    footer: GPane {
        leftPadding: constants.p3
        rightPadding: constants.p3
        bottomPadding: constants.p3
        contentItem: RowLayout {
            spacing: constants.s1
            HSpacer {
            }
            GButton {
                large: true
                text: qsTrId("Don't collect data")
                onClicked: {
                    Settings.analytics = 'disabled'
                    self.accept()
                }
            }
            GButton {
                highlighted: true
                large: true
                text: qsTrId('Allow collection')
                onClicked: {
                    Settings.analytics = 'enabled'
                    self.accept()
                }
            }
        }
    }
}
