function link(url, text) {
    return `<style>a:link { color: "#00B45A"; text-decoration: none; }</style><a href="${url}">${text || url}</a>`
}

function iconFor(target) {
    if (target instanceof Account) return iconFor(target.network)
    if (target instanceof Asset) {
        if (target.icon) return target.icon
        return iconFor(target.id)
    }
    if (target instanceof Wallet) return iconFor(target.network)
    if (target instanceof Network) return iconFor(target.key)
    switch (target) {
        case 'liquid':
            return 'qrc:/svg/liquid.svg'
        case 'testnet-liquid':
            return 'qrc:/svg/testnet-liquid.svg'
        case 'bitcoin':
            return 'qrc:/svg/btc.svg'
        case 'testnet':
            return 'qrc:/svg/btc_testnet.svg'
        case 'localtest':
            return 'qrc:/svg/localtest.svg'
        case 'localtest-liquid':
            return 'qrc:/svg/localtest-liquid.svg'
    }
    return 'qrc:/svg/generic_icon_30p.svg'
}

function formatTransactionTimestamp(tx) {
    return new Date(tx.created_at_ts / 1000).toLocaleString(locale.dateTimeFormat(Locale.LongFormat))
}

function accountName(account) {
    if (!account) return ''
    if (account.name !== '') return account.name
    if (account.mainAccount) return qsTrId('id_main_account')
    return qsTrId('Account %1').arg(account.pointer)
}

function dynamicScenePosition(item, x, y) {
    const target = item
    while (item) {
        item.x
        item.y
        item = item.parent
    }
    return target.mapToItem(null, x, y)
}

function findChildIndex(parent, pred) {
    if (!parent) return 0
    let index = 0
    for (let i = 0; i < parent.children.length; ++i) {
        const child = parent.children[i]
        if (!(child instanceof Item)) continue
        if (pred(child)) index = i
    }
    return index
}

function effectiveVisible(item) {
    while (item) {
        if (!item.visible) return false
        item = item.parent
    }
    return true
}

function effectiveWidth(item) {
    return item.visible ? item.width : 0
}

function accountLabel (account) {
    switch (account?.type) {
        case '2of2': return qsTrId('id_2of2')
        case '2of3': return qsTrId('id_2of3')
        case '2of2_no_recovery': return qsTrId('id_amp')
        case 'p2sh-p2wpkh': return qsTrId('id_legacy_segwit')
        case 'p2wpkh': return qsTrId('id_native_segwit')
        case 'p2pkh': return qsTrId('id_legacy')
        default: return qsTrId('-')
    }
}

function networkLabel (network) {
    if (!network) return '-'
    return network.electrum ? qsTrId('id_singlesig') : qsTrId('id_multisig')
}

function networkColor (network) {
    if (network.mainnet) {
        if (network.liquid) {
            return '#46BEAE'
        } else {
            return '#FF8E00'
        }
    } else if (network.localtest) {
        if (network.liquid) {
            return '#46BEAE'
        } else {
            return '#FF8E00'
        }
    } else {
        if (network.liquid) {
            return '#8C8C8C'
        } else {
            return '#8C8C8C'
        }
    }
}

function incognito(target, value, size) {
    let enabled = false
    if (target instanceof Account) enabled = target.context.wallet.incognito
    if (target instanceof Context) enabled = target.wallet.incognito
    if (enabled) {
        return value.replace(/\d\s\d/g, '0').replace(/[,.]/, '').replace(/\d+/g, '*'.repeat(size))
    } else {
        return value
    }
}

function incognitoFiat(target, value) {
    return incognito(target, value, 5)
}

function incognitoAmount(target, value) {
    return incognito(target, value, 5)
}

function normalizeUnit(unit) {
    return unit === '\u00B5BTC' ? 'ubtc' : unit.toLowerCase()
}

