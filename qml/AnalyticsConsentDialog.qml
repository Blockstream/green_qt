import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

AbstractDialog {
    Constants {
        id: constants
    }

    id: self
    title: qsTrId('id_help_green_improve')
    modal: false
    showRejectButton: true
    closePolicy: Dialog.NoAutoClose
    anchors.centerIn: undefined
    width: 420
    contentItem: ColumnLayout {
        spacing: constants.s2
        Label {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            text: qsTrId('id_if_you_agree_green_will_collect')
            wrapMode: Label.WordWrap
        }
        Pane {
            spacing: 0
            padding: constants.p2
            Layout.fillWidth: true
            background: Rectangle {
                color: constants.c500
                radius: 8
                Rectangle {
                    implicitHeight: 1
                    color: constants.c800
                    y: constants.p2 * 2 + details_label.height
                    width: parent.width
                }
            }
            TapHandler {
                onTapped: collapsible.toggle()
            }
            contentItem: ColumnLayout {
                spacing: 0
                Label {
                    id: details_label
                    Layout.fillWidth: true
                    text: collapsible.collapsed ? qsTrId('id_show_details') : qsTrId('id_hide_details')
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
                    Layout.fillWidth: true
                    id: collapsible
                    contentHeight: details_layout.height
                    contentWidth: collapsible.width
                    collapsed: true
                    ColumnLayout {
                        width: collapsible.width
                        id: details_layout
                        spacing: constants.s1
                        Label {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                            topPadding: constants.p3 + constants.p2
                            font.bold: true
                            text: qsTrId('id_whats_collected')
                        }
                        Label {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                            text: "• " + qsTrId('id_page_visits_button_presses')
                            wrapMode: Label.WordWrap
                        }
                        Label {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                            text: "• " + qsTrId('id_os__app_version_loading_times')
                            wrapMode: Label.WordWrap
                        }
                        Label {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                            topPadding: constants.p2
                            font.bold: true
                            text: qsTrId('id_whats_not_collected')
                        }
                        Label {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                            text: "• " + qsTrId('id_recovery_phrases_key_material')
                            wrapMode: Label.WordWrap
                        }
                        Label {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                            text: "• " + qsTrId('id_user_contact_info_ip_address')
                            wrapMode: Label.WordWrap
                        }
                        LinkLabel {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                            text: UtilJS.link('https://help.blockstream.com/hc/en-us/articles/5988514431897', qsTrId('id_learn_more'))
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
                text: qsTrId('id_dont_collect_data')
                onClicked: {
                    Settings.analytics = 'disabled'
                    self.accept()
                }
            }
            GButton {
                highlighted: true
                text: qsTrId('id_allow_collection')
                onClicked: {
                    Settings.analytics = 'enabled'
                    self.accept()
                }
            }
        }
    }
}
