import QtQuick

QtObject {
    property bool filterHasTransactions: false
    property var filterTypes: []
    property var calls: []

    function updateFilterHasTransactions(value) {
        calls = calls.concat([{ name: "updateFilterHasTransactions", value: value }])
        filterHasTransactions = value
    }

    function updateFilterTypes(type, enabled) {
        calls = calls.concat([{ name: "updateFilterTypes", type: type, enabled: enabled }])
        if (enabled) {
            if (filterTypes.indexOf(type) < 0) filterTypes = filterTypes.concat([type])
        } else {
            filterTypes = filterTypes.filter(v => v !== type)
        }
    }
}
