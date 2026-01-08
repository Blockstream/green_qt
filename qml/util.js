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

function iconFor(target) {
    if (target instanceof Account) return iconFor(target.network)
    if (target instanceof Asset) {
        if (target.icon) return target.icon
        if (target.policy) return iconFor(target.networkKey)
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

function formatTransactionTimestamp(transaction) {
    return new Date(transaction.data.created_at_ts / 1000).toLocaleString(locale.dateTimeFormat(Locale.LongFormat))
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
    if (target instanceof Account) return target.context.primarySession.unit
    if (target instanceof Context) return target.primarySession.unit
    if (target instanceof Session) return target.unit
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
    if (network && network.liquid) {
        return Math.round(fee_rate / 10) / 100 + ' sat/vbyte'
    } else {
        return Math.round(fee_rate / 100) / 10 + ' sat/vbyte'
    }
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
        if (wallet.login instanceof DeviceData) {
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
