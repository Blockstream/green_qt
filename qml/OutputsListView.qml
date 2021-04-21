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
        spacing: constants.p2

        ButtonGroup {
            id: button_group
        }

        Repeater {
            model: output_model_filter.tags

            Button {
                ButtonGroup.group: button_group
                background: Tag {
                    large: true
                    color: parent.checked ? constants.c200 : constants.c300
                    font.pixelSize: 16
                    font.styleName: "Medium"
                    text: modelData
                }
                onClicked: {
                    checked = true
                    output_model_filter.filterBy(modelData)
                }
            }
        }

        HSpacer {
        }

        ToolButton {
            visible: button_group.checkedButton
            icon.source: "qrc:/svg/cancel.svg"
            icon.width: 12
            icon.height: 12
            icon.color: 'white'
            padding: 0
            onClicked: {
                for (let i=0; i<button_group.buttons.length; ++i)
                    button_group.buttons[i].checked = false;

                button_group.checkedButton = null
                output_model_filter.clear()
            }
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
    }
}
