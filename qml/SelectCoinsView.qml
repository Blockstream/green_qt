import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.3
import QtQml.Models 2.11

import "analytics.js" as AnalyticsJS

Page {
    required property Account account

    readonly property var selectedOutputs: {
        const outputs = []
        for (var i=0; i<selection_model.selectedIndexes.length; ++i) {
            var index = selection_model.selectedIndexes[i]
            var o = output_model.data(index, Qt.UserRole)
            outputs.push(o)
        }
        return outputs;
    }

    property list<Action> options: [
        Action {
            enabled: selection_model.hasSelection
            text: qsTrId('id_clear')
            onTriggered: selection_model.clear()
        }
    ]

    id: self
    spacing: constants.p1
    background: null
    contentItem: ColumnLayout {
        RowLayout {
            id: tags_layout
            Layout.fillWidth: true
            spacing: 6

            ButtonGroup {
                id: button_group
            }

            Repeater {
                model: {
                    const filters = ['', 'csv', 'p2wsh']
                    if (account.wallet.network.liquid) {
                        filters.push('not_confidential')
                    } else {
                        filters.push('p2sh')
                        filters.push('dust')
                    }
                    if (account.type !== '2of3' && account.type !== '2of2_no_recovery') {
                        filters.push('expired')
                    }
                    return filters
                }
                delegate: Button {
                    id: self
                    ButtonGroup.group: button_group
                    checked: index === 0
                    checkable: true
                    padding: 18
                    topPadding: 10
                    bottomPadding: 10
                    background: Rectangle {
                        id: rectangle
                        radius: 4
                        color: self.checked ? constants.c300 : constants.c500
                    }
                    contentItem: Label {
                        text: self.text
                        font.pixelSize: 10
                        font.family: "Medium"
                    }
                    text: localizedLabel(modelData)
                    property string buttonTag: modelData
                    font.capitalization: Font.AllUppercase
                }
            }

            HSpacer {
            }
        }

        GListView {
            id: list_view
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 0
            model: OutputListModelFilter {
                id: output_model_filter
                filter: [button_group.checkedButton.buttonTag, '!locked'].join(' ')
                model: OutputListModel {
                    id: output_model
                    account: self.account
                    onModelAboutToBeReset: selection_model.clear()
                }
            }
            delegate: CoinDelegate {
                highlighted: selection_model.selectedIndexes.indexOf(output_model.index(output_model.indexOf(output), 0))>-1
                width: ListView.view.contentWidth
            }

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
                visible: list_view.count === 0
                anchors.centerIn: parent
                color: 'white'
                text: {
                    if (output_model_filter.filter === '') {
                        return qsTrId('id_youll_see_your_coins_here_when')
                    } else {
                        return qsTrId('id_there_are_no_results_for_the')
                    }
                }
            }

            ItemSelectionModel {
                id: selection_model
                model: output_model
            }
        }
    }
    AnalyticsView {
        active: self.visible
        name: 'SelectUTXO'
        segmentation: AnalyticsJS.segmentationSubAccount(self.account)
    }
}
