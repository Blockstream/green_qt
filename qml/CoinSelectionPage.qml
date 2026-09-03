import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

StackViewPage {
    id: self
    signal coinsSelected(var coins)

    required property Account account
    required property Asset asset
    required property var coins
    required property string unit
    property bool additionalCoins: false

    property var selection: {
        const selection = new Set();
        self.coins.forEach(output => selection.add(output));
        return selection;
    }
    property var activeFilters: []
    property var visibleOutputs: []
    property int sortMode: OutputListModelFilter.AmountDescending

    readonly property var sortOptions: [
        {
            label: 'Amount (High to Low)',
            value: OutputListModelFilter.AmountDescending
        },
        {
            label: 'Amount (Low to High)',
            value: OutputListModelFilter.AmountAscending
        },
        {
            label: 'Newest',
            value: OutputListModelFilter.Newest
        },
        {
            label: 'Oldest',
            value: OutputListModelFilter.Oldest
        },
    ]
    readonly property bool hasFilters: self.activeFilters.length > 0
    readonly property bool unavailable: output_model.fetching || output_model.error.length > 0
    readonly property bool allVisibleSelected: self.visibleOutputs.length > 0
        && self.visibleOutputs.every(output => self.selection.has(output))
    readonly property real selectedSatoshi: {
        let satoshi = 0;
        for (const output of self.selection) {
            satoshi += Number(output.data.satoshi ?? 0);
        }
        return satoshi;
    }

    function toggleOutput(output) {
        const selection = new Set(self.selection);
        if (selection.has(output))
            selection.delete(output);
        else
            selection.add(output);
        self.selection = selection;
    }

    function toggleFilter(filter) {
        const filters = [...self.activeFilters];
        const index = filters.indexOf(filter);
        if (index < 0)
            filters.push(filter);
        else
            filters.splice(index, 1);
        self.activeFilters = filters;
    }

    function updateVisibleOutputs() {
        const outputs = [];
        for (let i = 0; i < output_model_filter.rowCount(); ++i) {
            outputs.push(output_model_filter.outputAt(i));
        }
        self.visibleOutputs = outputs;
    }

    function toggleAllVisible() {
        self.updateVisibleOutputs();
        const selection = new Set(self.selection);
        const unselect = self.allVisibleSelected;
        for (const output of self.visibleOutputs) {
            if (unselect)
                selection.delete(output);
            else
                selection.add(output);
        }
        self.selection = selection;
    }

    function confirmSelection() {
        const coins = [];
        if (output_model.error.length === 0) {
            for (const output of self.selection)
                coins.push(output);
        }
        self.coinsSelected(coins);
    }
    title: 'Coin Selection'
    leftItem: BackButton {
        onClicked: self.popPage()
    }

    OutputListModel {
        id: output_model
        allCoins: false
        account: self.account
    }

    OutputListModelFilter {
        id: output_model_filter
        activeFilters: self.activeFilters
        asset: self.asset
        excludeLocked: true
        model: output_model
        sortMode: self.sortMode
    }

    Component.onCompleted: self.updateVisibleOutputs()

    Connections {
        target: output_model_filter
        function onModelReset() { self.updateVisibleOutputs() }
        function onRowsInserted() { self.updateVisibleOutputs() }
        function onRowsRemoved() { self.updateVisibleOutputs() }
        function onRowsMoved() { self.updateVisibleOutputs() }
        function onLayoutChanged() { self.updateVisibleOutputs() }
        function onDataChanged() { self.updateVisibleOutputs() }
    }

    Convert {
        id: selected_convert
        account: self.account
        asset: self.asset
        input: ({
                satoshi: String(self.selectedSatoshi)
            })
        unit: self.unit
    }

    AnalyticsView {
        active: self.visible
        name: 'SelectUTXO'
        segmentation: AnalyticsJS.segmentationSubAccount(self.account)
    }

    contentItem: ColumnLayout {
        spacing: 16

        Label {
            Layout.fillWidth: true
            color: '#A0A0A0'
            font.pixelSize: 14
            font.weight: 400
            text: self.additionalCoins
                ? 'Choose additional coins to use for the fee increase.'
                : 'Choose which coins to use for the transaction.'
            wrapMode: Label.WordWrap
        }

        ColumnLayout {
            spacing: 8
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Label {
                    color: '#A0A0A0'
                    font.pixelSize: 14
                    font.weight: 400
                    text: qsTrId('id_coins')
                }

                HSpacer {
                }

                GComboBox {
                    id: sort_combo
                    model: self.sortOptions
                    textRole: 'label'
                    triggerIconSource: 'qrc:/svg2/sort-ascending.svg'
                    triggerYPadding: 4
                    valueRole: 'value'
                    currentIndex: self.sortOptions.findIndex(option => option.value === self.sortMode)
                    popup.width: 240
                    onActivated: (index) => self.sortMode = sort_combo.model[index].value
                }

                GComboBox {
                    id: filter_combo
                    checkedRole: 'checked'
                    iconRole: 'icon'
                    model: {
                        const options = []
                        if (self.account.type !== '2of3' && !self.account.amp0) {
                            options.push({ text: qsTrId('id_2fa_expired'), value: 'expired_2fa', icon: 'qrc:/svg2/timer.svg' })
                        }
                        if (!self.account.network.liquid) {
                            options.push({ text: qsTrId('id_dust'), value: 'dust', icon: 'qrc:/svg2/dust.svg' })
                        }
                        if (!self.account.network.liquid && self.account.type === '2of2') {
                            options.push({ text: 'Legacy Recovery', value: 'legacy_recovery', icon: 'qrc:/svg2/arrows-clockwise.svg' })
                        }
                        return options.map(option => ({
                            text: option.text,
                            value: option.value,
                            icon: option.icon,
                            checked: self.activeFilters.includes(option.value)
                        }))
                    }
                    textRole: 'text'
                    triggerYPadding: 4
                    valueRole: 'value'
                    currentIndex: -1
                    popup.width: 220
                    visible: filter_combo.model.length > 0
                    triggerContent: Component {
                        Item {
                            implicitWidth: 24
                            implicitHeight: 24
                            Image {
                                anchors.centerIn: parent
                                source: 'qrc:/svg2/funnel.svg'
                            }
                            Rectangle {
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.rightMargin: -5
                                anchors.topMargin: -4
                                width: 11
                                height: 11
                                border.color: '#121416'
                                border.width: 2
                                color: '#00BCFF'
                                radius: width / 2
                                visible: self.hasFilters
                            }
                        }
                    }
                    onActivated: (index) => {
                        const value = filter_combo.model[index].value
                        self.toggleFilter(value)
                        filter_combo.currentIndex = -1
                    }
                }
            }

            TListView {
                id: list_view
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 4
                model: output_model_filter
                visible: !self.unavailable && count > 0
                delegate: CoinSelectionDelegate {
                    id: coin_delegate
                    checked: self.selection.has(coin_delegate.output)
                    unit: self.unit
                    width: ListView.view.width
                    onClicked: self.toggleOutput(coin_delegate.output)
                    onDetailsRequested: self.pushPage(coin_details_page, {
                        output: coin_delegate.output,
                        unit: self.unit
                    })
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12
            visible: output_model.fetching

            VSpacer {}

            BusyIndicator {
                Layout.alignment: Qt.AlignHCenter
                running: output_model.fetching
            }

            Label {
                Layout.alignment: Qt.AlignHCenter
                color: '#929292'
                font.pixelSize: 14
                text: qsTrId('id_loading')
            }

            VSpacer {}
        }

        EmptyState {
            iconHeight: 40
            iconWidth: 40
            iconSource: 'qrc:/svg2/empty.svg'
            title: qsTrId('id_error')
            description: 'Unable to load coins. Please try again'
            action: 'Retry'
            visible: output_model.error.length > 0
            onTriggered: output_model.fetch()
        }

        EmptyState {
            iconHeight: 40
            iconWidth: 40
            iconSource: 'qrc:/svg2/funnel-x.svg'
            title: 'No coins match your filters'
            description: 'Try adjusting or resetting your filters.'
            action: 'Reset Filters'
            visible: !self.unavailable && self.hasFilters && list_view.count === 0
            onTriggered: self.activeFilters = []
        }

        EmptyState {
            iconHeight: 40
            iconWidth: 40
            iconSource: 'qrc:/svg2/funnel-x.svg'
            title: 'No coins available'
            description: qsTrId('id_youll_see_your_coins_here_when')
            visible: !self.unavailable && !self.hasFilters && list_view.count === 0
        }
    }

    footerItem: ColumnLayout {
        spacing: 20

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: '#262626'
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Label {
                    color: '#A0A0A0'
                    font.pixelSize: 14
                    font.weight: 400
                    text: self.selection.size + ' ' + (self.selection.size === 1 ? 'Coin Selected' : 'Coins Selected')
                }

                LinkButton {
                    enabled: !self.unavailable && list_view.count > 0
                    text: self.allVisibleSelected ? 'Unselect All' : 'Select All'
                    onClicked: self.toggleAllVisible()
                }
            }

            HSpacer {}

            ColumnLayout {
                spacing: 2

                Label {
                    Layout.alignment: Qt.AlignRight
                    color: '#FAFAFA'
                    font.pixelSize: 14
                    font.weight: 600
                    text: {
                        if (self.selection.size > 0) return UtilJS.incognito(Settings.incognito, selected_convert.output.label)
                        if (output_model.fetching) return qsTrId('id_loading')
                        if (self.additionalCoins) {
                            if (output_model.error.length > 0) return 'Unable to load coins'
                            if (list_view.count === 0) return self.hasFilters ? 'No coins match your filters' : 'No coins available'
                            return 'No additional coins selected'
                        }
                        return list_view.count > 0 && !self.unavailable ? 'Using all available coins' : 'No coins available'
                    }
                }

                Label {
                    Layout.alignment: Qt.AlignRight
                    color: '#A0A0A0'
                    font.pixelSize: 12
                    text: UtilJS.incognito(Settings.incognito, selected_convert.fiat.label)
                    visible: self.selection.size > 0 && selected_convert.fiat.available
                }

                Label {
                    Layout.alignment: Qt.AlignRight
                    color: '#A0A0A0'
                    font.pixelSize: 12
                    text: 'No coins available'
                    visible: !self.unavailable && self.selection.size > 0 && list_view.count === 0
                }
            }
        }

        PrimaryButton {
            Layout.fillWidth: true
            enabled: !output_model.fetching
            text: qsTrId('id_confirm')
            onClicked: self.confirmSelection()
        }
    }

    Component {
        id: coin_details_page
        CoinDetailsPage {
            onCloseClicked: self.closeClicked()
        }
    }

    component EmptyState: ColumnLayout {
        id: empty_state
        signal triggered

        property string title
        property string description
        property string action
        property int iconHeight
        property string iconSource
        property int iconWidth
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 12

        VSpacer {}

        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 48
            Layout.preferredWidth: 48
            Image {
                anchors.centerIn: parent
                width: empty_state.iconWidth
                height: empty_state.iconHeight
                source: empty_state.iconSource
            }
        }

        Label {
            Layout.fillWidth: true
            color: '#FFFFFF'
            font.pixelSize: 18
            font.weight: 600
            horizontalAlignment: Label.AlignHCenter
            text: parent.title
            wrapMode: Label.WordWrap
        }

        Label {
            Layout.fillWidth: true
            color: '#929292'
            font.pixelSize: 14
            horizontalAlignment: Label.AlignHCenter
            text: parent.description
            visible: text.length > 0
            wrapMode: Label.WordWrap
        }

        LinkButton {
            Layout.alignment: Qt.AlignHCenter
            text: parent.action
            visible: text.length > 0
            onClicked: parent.triggered()
        }

        VSpacer {}
    }
}
