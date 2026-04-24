import QtQuick

QtObject {
    property var filterAccounts: []
    property var filterAssets: []
    property var calls: []

    function updateFilterAccounts(account, enabled) {
        calls = calls.concat([{ name: "updateFilterAccounts", account: account, enabled: enabled }])
        if (enabled) {
            if (filterAccounts.indexOf(account) < 0) filterAccounts = filterAccounts.concat([account])
        } else {
            filterAccounts = filterAccounts.filter(v => v !== account)
        }
    }

    function updateFilterAssets(asset, enabled) {
        calls = calls.concat([{ name: "updateFilterAssets", asset: asset, enabled: enabled }])
        if (enabled) {
            if (filterAssets.indexOf(asset) < 0) filterAssets = filterAssets.concat([asset])
        } else {
            filterAssets = filterAssets.filter(v => v !== asset)
        }
    }
}
