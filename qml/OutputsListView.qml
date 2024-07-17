import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQml.Models

Page {
    signal updateUnspentsClicked(var unspents, string status)
    required property Account account

    readonly property var selectedOutputs: {
        const outputs = []
        for (var i = 0; i < selection_model.selectedIndexes.length; i++) {
            const index = selection_model.selectedIndexes[i]
            const output = output_model.data(index, Qt.UserRole)
            outputs.push(output)
        }
        return outputs;
    }
    readonly property var filters: {
        const account = self.account
        const network = account.network
        const filters = ['', 'csv', 'p2wsh']
        if (network.liquid) {
            filters.push('not_confidential')
        } else {
            filters.push('p2sh')
            filters.push('dust')
            if (!network.electrum) filters.push('locked')
        }
        if (!network.electrum && account.type !== '2of3' && account.type !== '2of2_no_recovery') {
            filters.push('expired')
        }
        return filters
    }
    property string filter: self.filters[0]

    OutputListModel {
        id: output_model
        account: self.account
        onModelAboutToBeReset: selection_model.clear()
    }

    OutputListModelFilter {
        id: output_model_filter
        filter: self.filter
        model: output_model
    }

    ItemSelectionModel {
        id: selection_model
        model: output_model
    }

    id: self
    padding: 0
    focusPolicy: Qt.ClickFocus
    background: Rectangle {
        color: '#161921'
        border.width: 1
        border.color: '#1F222A'
        radius: 4
        Label {
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
    }
    contentItem: TListView {
        id: list_view
        bottomMargin: 120
        spacing: -1
        model: output_model_filter
        delegate: OutputDelegate {
            id: delegate
            highlighted: selection_model.selectedIndexes.indexOf(output_model.index(output_model.indexOf(output), 0))>-1
            width: ListView.view.width
            onClicked: {
                selection_model.select(output_model.index(output_model.indexOf(delegate.output), 0), ItemSelectionModel.Toggle)
            }
        }
    }
    header: Collapsible {
        id: collapsible
        collapsed: !(selection_model.hasSelection && !account.network.liquid)
        animationVelocity: 300
        Pane {
            width: collapsible.width
            background: null
            padding: 20
            contentItem: RowLayout {
                spacing: 20
                Label {
                    text: selection_model.selectedIndexes.length + ' selected'
                    padding: 4
                }
                HSpacer {
                }
                LinkButton {
                    text: qsTrId('id_lock')
                    enabled: {
                        if (self.account.network.electrum) return false
                        if (self.account.network.liquid) return false
                        for (const output of selectedOutputs) {
                            if (output.locked) return false
                            if (!output.canBeLocked) return false
                            if (output.unconfirmed) return false
                        }
                        return true
                    }
                    onClicked: {
                        self.updateUnspentsClicked(selectedOutputs, 'frozen')
                    }
                }
                LinkButton {
                    text: qsTrId('id_unlock')
                    enabled: {
                        for (const output of selectedOutputs) {
                            if (!output.locked) return false;
                        }
                        return true;
                    }
                    onClicked: {
                        self.updateUnspentsClicked(selectedOutputs, 'default')
                    }
                }
                LinkButton {
                    text: qsTrId('id_clear')
                    onClicked: selection_model.clear();
                }
            }
        }
    }
    RowLayout {
        parent: toolbarItem
        visible: self.visible
        spacing: 10
        AbstractButton {
            id: unit_label
            leftPadding: 6
            rightPadding: 6
            bottomPadding: 4
            topPadding: 4
            contentItem: RowLayout {
                spacing: 4
                Label {
                    color: unit_label.enabled && unit_label.hovered ? '#00DD6E' : '#00B45A'
                    font.pixelSize: 16
                    font.weight: 500
                    text: localizedLabel(self.filter)
                }
                Image {
                    Layout.alignment: Qt.AlignCenter
                    source: 'qrc:/svg2/caret-down.svg'
                    visible: unit_label.enabled
                }
            }
            onClicked: unit_menu.open()
            background: Rectangle {
                border.width: 2
                border.color: '#00B45A'
                color: 'transparent'
                visible: unit_label.visualFocus
            }
            GMenu {
                id: unit_menu
                x: unit_label.width * 0.5 - unit_menu.width * 0.8
                y: unit_label.height + 8
                pointerX: 0.8
                pointerY: 0
                Repeater {
                    model: self.filters
                    delegate: GMenu.Item {
                        hideIcon: true
                        text: localizedLabel(modelData)
                        onClicked: {
                            unit_menu.close()
                            self.filter = modelData
                        }
                    }
                }
            }
        }
    }

    Component {
        id: info_dialog
        AbstractDialog {
            title: qsTrId('id_filters')
            icon: "qrc:/svg/info.svg"
            contentItem: ColumnLayout {
                spacing: constants.p3
                Repeater {
                    model: ['all', 'csv', 'p2wsh', 'p2sh', 'not_confidential', 'dust', 'locked', 'expired']
                    delegate: RowLayout {
                        spacing: constants.p1

                        Tag {
                            text: localizedLabel(modelData)
                            Layout.minimumWidth: 120
                            Layout.alignment: Qt.AlignTop
                            horizontalAlignment: Label.AlignHCenter
                            font.capitalization: Font.AllUppercase
                        }

                        Label {
                            Layout.maximumWidth: 400
                            text: {
                                switch (modelData) {
                                    case 'all':
                                        return qsTrId('id_all_the_coins_received_or')
                                    case 'csv':
                                        return qsTrId('id_coins_protected_by_the_new')
                                    case 'p2wsh':
                                        return qsTrId('id_coins_protected_by_the_legacy')
                                    case 'p2sh':
                                        return qsTrId('id_coins_received_or_created')
                                    case 'not_confidential':
                                        return qsTrId('id_coins_whose_asset_and_amount')
                                    case 'dust':
                                        return qsTrId('id_coins_with_a_value_lower_than')
                                    case 'locked':
                                        return qsTrId('id_locking_coins_can_help_protect')
                                    case 'expired':
                                        return qsTrId('id_coins_for_which_2fa_protection')
                                }
                            }
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }
    }
}
