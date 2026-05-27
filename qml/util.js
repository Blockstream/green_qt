.pragma library

function formatError(error) {
    if (!error) return ''
    if (error === 'id_rate_limited') {
        return 'The Electrum server is rate limiting requests. Please wait a moment and try again.'
    }
    if (error === 'id_rate_connection_limited') {
        return 'Too many connections to the Electrum server. Please wait a moment and try again.'
    }
    if (typeof error === 'string' && error.startsWith('id_')) return qsTrId(error)
    return error
}

function flatten(...args) {
    const result = []
    for (const arg of args) {
        if (!arg) continue
        if (arg.length >= 0) {
            for (let i = 0; i < arg.length; i++) {
                result.push(arg[i])
            }
        } else {
            result.push(arg)
        }
    }
    return result
}

function link(url, text) {
    return `<style>a:link { color: "#00BCFF"; text-decoration: none; }</style><a href="${url}">${text || url}</a>`
}

function accountIcon(account) {
    return networkIcon(account.network)
}

function assetIcon(asset) {
    if (asset.icon) return asset.icon
    if (asset.policy) return iconFor(asset.networkKey)
    return iconFor(asset.id)
}

function networkIcon(network) {
    return iconFor(network.key)
}

function iconFor(target) {
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

function formatTransactionTimestamp(transaction, locale) {
    return new Date(transaction.data.created_at_ts / 1000).toLocaleString(locale.dateTimeFormat(0)) //Locale.LongFormat))
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

function accounts(context) {
    if (!context) return []

    return context.accounts.filter(account => !account.hidden)
}

function archivedAccounts(context) {
    if (!context) return []

    const has_multisig_liquid_amp = context.accounts.filter(account => !account.network.electrum && account.network.liquid && account.type === '2of2_no_recovery').length > 0
    const has_multisig_liquid_except_amp = context.accounts.filter(account => !account.network.electrum && account.network.liquid && account.type !== '2of2_no_recovery' && (account.pointer > 0 || !account.hidden)).length > 0

    return context.accounts.filter(account => {
        if (!account.hidden) return false
        if (account.network.liquid && !account.network.electrum && account.pointer === 0 && !has_multisig_liquid_except_amp && has_multisig_liquid_amp) return false
        return true
    })
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

function assets(context) {
    if (!context) return []
    const assets = new Map
    for (let i = 0; i < context.sessions.length; i++) {
        const session = context.sessions[i]
        const asset = context.getOrCreateAsset(session.network.policyAsset)
        assets.set(asset, { asset, satoshi: 0 })
    }
    for (const account of accounts(context)) {
        for (let asset_id in account.json.satoshi) {
            const satoshi = account.json.satoshi[asset_id]
            const asset = context.getOrCreateAsset(asset_id)
            let sum = assets.get(asset)
            if (sum) {
                sum.satoshi += satoshi
            } else {
                sum = { satoshi, asset }
                assets.set(asset, sum)
            }
        }
    }
    return [...assets.values()].sort((a, b) => {
        if (a.asset.weight > b.asset.weight) return -1
        if (b.asset.weight > a.asset.weight) return 1
        if (b.asset.weight === 0) {
            if (a.asset.icon && !b.asset.icon) return -1
            if (!a.asset.icon && b.asset.icon) return 1
            if (Object.keys(a.asset.data).length > 0 && Object.keys(b.asset.data).length === 0) return -1
            if (Object.keys(a.asset.data).length === 0 && Object.keys(b.asset.data).length > 0) return 1
        }
        return a.asset.name.localeCompare(b.asset.name)
    })
}

function networkLabel (network) {
    if (!network) return '-'
    return network.electrum ? qsTrId('id_singlesig') : qsTrId('id_multisig')
}

function networkColor (network) {
    const c = Qt.color(network.liquid ? '#46BEAE' : '#FF8E00')
    if (!network.mainnet) {
        c.hsvValue *= 0.5
        c.hsvSaturation *= 0.1
    }
    return c
}

function incognito(enabled, value, size = 5) {
    if (enabled) {
        return value
            .replace('~ ', '')
            .replace('-', '')
            .replace(/\d\s\d/g, '0')
            .replace(/[,.]/g, '')
            .replace(/\d+/g, '*'.repeat(size))
    } else {
        return value
    }
}

function unit(target) {
    return target.primarySession.unit
}

function currency(context) {
    return context.primarySession?.settings?.pricing?.currency ?? 'USD'
}

function formatAmount(amount, currency, options = {}) {
    const locale = options.locale ?? Qt.locale()
    const precision = options.precision ?? 2

    const value = Number(amount)
    if (!isFinite(value)) return currency ? `-/- ${currency}` : ''

    let formatted = locale.toString(value, 'f', precision)
    const decimalPoint = locale.decimalPoint
    if (formatted.includes(decimalPoint)) {
        while (formatted.endsWith('0')) {
            formatted = formatted.slice(0, -1)
        }
        if (formatted.endsWith(decimalPoint)) {
            formatted = formatted.slice(0, -decimalPoint.length)
        }
    }

    return currency ? `${formatted} ${currency}` : formatted
}

function normalizeUnit(unit) {
    return unit === '\u00B5BTC' ? 'ubtc' : unit.toLowerCase()
}

function getUnblindingData(tx) {
    return {
        version: 0,
        txid: tx.txhash,
        type: tx.type,
        inputs: tx.inputs
            .filter(i => i.asset_id && i.satoshi && i.assetblinder && i.amountblinder)
            .map(i => ({
               vin: i.pt_idx,
               asset_id: i.asset_id,
               assetblinder: i.assetblinder,
               satoshi: i.satoshi,
               amountblinder: i.amountblinder,
            })),
        outputs: tx.outputs
            .filter(o => o.asset_id && o.satoshi && o.assetblinder && o.amountblinder)
            .map(o => ({
               vout: o.pt_idx,
               asset_id: o.asset_id,
               assetblinder: o.assetblinder,
               satoshi: o.satoshi,
               amountblinder: o.amountblinder,
            })),
    }
}

function confirmations(session, block_height) {
    if (block_height === 0) return 0
    return 1 + session.block.block_height - block_height
}

function transactionTypeLabel(transaction) {
    if (transaction.data.type === 'incoming') {
        if ((transaction.data.outputs?.length ?? 0) > 0) {
            for (const output of transaction.data.outputs) {
                if (output.is_relevant) {
                    return qsTrId('id_received')
                }
            }
        } else {
            return qsTrId('id_received')
        }
    }
    if (transaction.data.type === 'outgoing') {
        return qsTrId('id_sent')
    }
    if (transaction.data.type === 'redeposit') {
        return qsTrId('id_redeposited')
    }
    if (transaction.data.type === 'mixed') {
        return qsTrId('id_swap')
    }
    if (transaction.data.type === 'not unblindable') {
        return 'Not unblindable'
    }
    return transaction.data.type
}

function transactionIcon(type, confirmations)
{
    return confirmations > 0 ? `qrc:/svg2/tx-${type}.svg` : 'qrc:/ffffff/24/hourglass-high.svg'
}

function twoFactorMethodLabel(method)
{
    const labels = {
        email: 'id_email',
        gauth: 'id_authenticator_app',
        phone: 'id_phone_call',
        sms: 'id_sms',
        telegram: 'id_telegram',
    }
    return qsTrId(labels[method])
}

function shuffle(a) {
    const b = a.slice()
    const c = []
    while (b.length) {
        const [d] = b.splice(Math.floor(Math.random() * b.length), 1)
        c.push(d)
    }
    return c
}

function csvTimeLabel(blocks) {
    const hours = Math.round(blocks / 6)
    if (hours <= 1) return '~1 ' + qsTrId('id_hour')
    if (hours < 24) return hours + ' ' + qsTrId('id_hours')
    const days = Math.round(blocks / 6 / 24)
    if (days <= 1) return '1 ' + qsTrId('id_day')
    if (days < 30) return days + qsTrId('id_days')
    const months = Math.round(blocks / 6 / 24 / 30)
    if (months <= 1) return '1 ' + qsTrId('id_month')
    return months + ' ' + qsTrId('id_months')
}

function csvLabel(blocks) {
    return csvTimeLabel(blocks) + ' (' + blocks + ' ' + qsTrId('id_blocks') + ')'
}

/// Generates a pair of initials from a provider name
function getProviderInitials(name) {
    if (!name || name.length === 0) return '--'
    const components = name.split(' ')
    if (components.length > 1) {
        const first = components[0].substring(0, 1)
        const second = components[1].substring(0, 1)
        return (first + second).toUpperCase()
    } else {
        return name.substring(0, 2).toUpperCase()
    }
}

/// Creates a deterministic color based on a provider name
function colorFromProviderName(name) {
    if (!name || name.length === 0) return '#4FD1FF'
    let hash = 0
    for (let i = 0; i < name.length; i++) {
        hash = ((hash << 5) - hash) + name.charCodeAt(i)
        hash = hash | 0
    }
    const hue = Math.abs(hash % 360) / 360.0
    return Qt.hsla(hue, 0.75, 0.55, 1.0)
}

function formatFeeRate(fee_rate, network) {
    if (network?.liquid) {
        return Math.round(fee_rate / 10) / 100 + ' sat/vbyte'
    } else {
        return Math.round(fee_rate / 100) / 10 + ' sat/vbyte'
    }
}

function confirmationTime(rate, estimates) {
    if (estimates?.length !== 25) return '-'
    if (estimates[24] < estimates[12] && rate < estimates[24]) {
        return qsTrId('id_custom')
    }
    if (estimates[12] < estimates[3] && rate < estimates[12]) {
        return qsTrId('id_4_hours')
    }
    if (rate < estimates[3]) {
        return qsTrId('id_2_hours')
    }
    return qsTrId('id_1030_minutes')
}

function filterPromo(wallets, promo) {
    const target = promo?.data?.target
    if (!target) return true
    let sww = 0
    let hww = 0
    let jade_classic = 0
    let jade_plus = 0
    for (let i = 0; i < wallets.length; i++) {
        const wallet = wallets[i]
        if (wallet.login?.device) {
            hww ++
            const device = wallet.login.device
            if (device.type === 'jade') {
                if (device.board === 'JADE_V2') {
                    jade_plus ++
                } else {
                    jade_classic ++
                }
            }
        } else {
            sww ++
        }
    }
    console.log('filter promo', promo.id, target, sww, hww, jade_classic, jade_plus)
    if (target === 'only_sww') {
        return sww > 0 && hww === 0
    } else if (target === 'jade_user') {
        return jade_classic > 0 && jade_plus === 0
    } else if (target === 'jadeplus_user') {
        return jade_plus > 0
    }
    return true
}

function isJadeV2(boardType) {
    return boardType?.startsWith('JADE_V2') ?? false
}


function jadeImage(device, index) {
    const type = device.versionInfo?.BOARD_TYPE
    const version = isJadeV2(type) ? 'jade2' : 'jade'
    return `qrc:/png/${version}_${index}.png`
}

function localizedLabel(label) {
    switch (label) {
        case '':
        case 'all':
            return qsTrId('id_all')
        case 'csv':
            return qsTrId('id_csv')
        case 'p2wsh':
            return qsTrId('id_p2wsh')
        case 'p2sh':
            return qsTrId('id_p2sh')
        case 'not_confidential':
            return qsTrId('id_not_confidential')
        case 'dust':
            return qsTrId('id_dust')
        case 'locked':
            return qsTrId('id_locked')
        case 'expired':
            return qsTrId('id_2fa_expired')
        case 'p2wpkh':
            return 'p2wpkh'
        case 'p2sh-p2wpkh':
            return 'p2sh-p2wpkh'
        case 'p2tr':
            return 'p2tr'
        default:
            console.warn(`missing localized label for ${label}`)
            console.trace()
            return label
    }
}

function swapNetworkType(network) {
    if (network?.liquid) return 'liquid'
    if (network?.mainnet) return 'mainnet'
    return null
}

function isAmpAccount(account) {
    return account?.type === '2of2_no_recovery'
}
