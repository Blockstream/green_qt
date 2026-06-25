import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

StackViewPage {
    id: self
    required property var error
    readonly property string errorText: UtilJS.formatError(self.error)
    leftItem: Item {}
    centerItem: Item {}
    rightItem: CloseButton {
        onClicked: self.closeClicked()
    }
    footerItem: PrimaryButton {
        Layout.fillWidth: true
        text: qsTrId('id_ok')
        onClicked: self.closeClicked()
    }
    contentItem: ColumnLayout {
        spacing: 48
        CanceledImage {
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 100
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 20
            Label {
                Layout.fillWidth: true
                font.pixelSize: 24
                font.weight: 700
                horizontalAlignment: Label.AlignHCenter
                text: qsTrId('id_transaction_failed')
                wrapMode: Label.WordWrap
            }
            ErrorDetailsPane {
                Layout.fillWidth: true
                errorText: self.errorText
            }
        }
        VSpacer {}
    }

    component ErrorDetailsPane: Pane {
        id: error_details_pane
        required property string errorText
        horizontalPadding: 16
        verticalPadding: 12
        background: Rectangle {
            color: '#181818'
            radius: 4
        }
        contentItem: RowLayout {
            spacing: 12
            Label {
                Layout.fillWidth: true
                color: '#FFFFFF'
                font.family: 'Roboto Mono'
                font.pixelSize: 14
                font.weight: 400
                lineHeight: 18
                lineHeightMode: Text.FixedHeight
                opacity: 0.8
                text: error_details_pane.errorText
                wrapMode: Label.Wrap
            }
            AbstractButton {
                id: copy_button
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                icon.source: copy_timer.running ? 'qrc:/svg2/check.svg' : 'qrc:/svg2/copy.svg'
                onClicked: {
                    Clipboard.copy(error_details_pane.errorText)
                    copy_timer.restart()
                }
                Timer {
                    id: copy_timer
                    interval: 1000
                    repeat: false
                }
                contentItem: Image {
                    source: copy_button.icon.source
                    opacity: copy_button.hovered ? 1 : 0.6
                }
            }
        }
    }
}
