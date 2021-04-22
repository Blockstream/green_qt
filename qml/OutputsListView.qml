import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.3

ColumnLayout {
    required property Account account

    id: self
    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: constants.p2

    RowLayout {
        id: tags_layout
        Layout.fillWidth: true
        implicitHeight: 50
        spacing: constants.p1

        ButtonGroup {
            id: button_group
        }

        Repeater {
            model: account.wallet.network.liquid ? ['all', 'csv', 'p2wsh', 'expired', 'not confidential'] : ['all', 'csv', 'p2wsh', 'dust', 'frozen']

            Button {
                ButtonGroup.group: button_group
                checked: index === 0
                background: Tag {
                    large: true
                    color: parent.checked ? constants.c200 : constants.c300
                    font.pixelSize: 12
                    font.styleName: "Medium"
                    font.capitalization: Font.AllUppercase
                    text: modelData
                }
                onClicked: {
                    checked = true
                    output_model_filter.filter = modelData
                }
            }
        }

        HSpacer {
        }
    }

    ListView {
        id: list_view
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 8
        model: OutputListModelFilter {
            id: output_model_filter
            model: OutputListModel {
                id: output_model
                account: self.account
            }
        }
        delegate: OutputDelegate {
            hoverEnabled: false
            width: list_view.width
        }

        ScrollIndicator.vertical: ScrollIndicator { }

        BusyIndicator {
            width: 32
            height: 32
            running: output_model.fetching
            anchors.margins: 8
            Layout.alignment: Qt.AlignHCenter
            opacity: output_model.fetching ? 1 : 0
            Behavior on opacity { OpacityAnimator {} }
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Label {
            id: label
            visible: list_view.count===0
            anchors.centerIn: parent
            color: 'white'
            states: [
                State {
                    when: output_model_filter.filter ==='all'
                    PropertyChanges { target: label; text: "You'll see your coins here when you receive funds" }
                },
                State {
                    when: output_model_filter.filter !=='all'
                    PropertyChanges { target: label; text: "There are no results for the applied filter" }
                }
            ]
        }
    }
}
