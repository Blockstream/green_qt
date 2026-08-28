.pragma library

.import Blockstream.Green.Core as Core
.import "util.js" as UtilJS

function segmentationNetwork(context) {
    const segmentation = {
        security: 'singlesig',
        segment: 'Desktop',
        wallet_networks: context ? context.mainnet ? 'mainnet' : 'testnet' : null
    }
    if (!context) return segmentation

    let mainnet = false
    let liquid = false
    let testnet = false
    let testnet_liquid = false
    let singlesig = false
    let multisig = false

    for (const account of UtilJS.accounts(context)) {
        const network = account.network
        mainnet = mainnet || (network.mainnet && !network.liquid)
        liquid = liquid || (network.mainnet && network.liquid)
        testnet = testnet || (!network.mainnet && !network.liquid)
        testnet_liquid = testnet_liquid || (!network.mainnet && network.liquid)
        singlesig = singlesig || network.electrum
        multisig = multisig || !network.electrum
    }

    if (context.mainnet) {
        if (mainnet && liquid) {
            segmentation.wallet_networks = 'mainnet-mixed'
        } else if (mainnet && !liquid) {
            segmentation.wallet_networks = 'mainnet'
        } else if (!mainnet && liquid) {
            segmentation.wallet_networks = 'liquid'
        }
    } else {
        if (testnet && testnet_liquid) {
            segmentation.wallet_networks = 'testnet-mixed'
        } else if (testnet && !liquid) {
            segmentation.wallet_networks = 'testnet'
        } else if (!testnet && liquid) {
            segmentation.wallet_networks = 'testnet-liquid'
        }
    }

    if (singlesig && multisig) {
        segmentation.security = 'single-multi'
    } else if (singlesig) {
        segmentation.security = 'singlesig'
    } else if (multisig) {
        segmentation.security = 'multisig'
    }

    return segmentation
}

function segmentationOnBoard({ flow, network, security }) {
    const segmentation = {
        segment: 'Desktop',
    }
    if (flow) segmentation.flow = flow
    if (network) segmentation.network = network
    if (security) segmentation.security = security
    return segmentation
}

function segmentationSession(context) {
    const segmentation = segmentationNetwork(context)
    const app_settings = []
    if (Core.Settings.useTor) app_settings.push('tor')
    if (Core.Settings.useProxy) app_settings.push('proxy')
    if (Core.Settings.enableTestnet) app_settings.push('testnet')
    if (Core.Settings.usePersonalNode) app_settings.push('electrum_server')
    segmentation.app_settings = app_settings.join(',')
    if (context?.device) {
        const device = context.device
        if (device.type === 1) {
            segmentation.brand = 'Blockstream'
            if (device.versionInfo) {
                segmentation.model = device.versionInfo.BOARD_TYPE
            }
            segmentation.firmware = device.version
            segmentation.connection = 'USB'
        }
        if (device.type === 2) {
            segmentation.brand = 'Ledger'
            segmentation.model = 'Ledger Nano S'
            segmentation.firmware = device.appVersion
            segmentation.connection = 'USB'
        }
        if (device.type === 3) {
            segmentation.brand = 'Ledger'
            segmentation.model = 'Ledger Nano X'
            segmentation.firmware = device.appVersion
            segmentation.connection = 'USB'
        }
    }
    return segmentation
}

function segmentationPromo(context, promo, screen) {
    const segmentation = segmentationSession(context)
    segmentation.promo_id = promo.id
    segmentation.screen = screen
    return segmentation
}

function segmentationFirmwareUpdate(device, firmware) {
    const segmentation = {
        segment: 'Desktop',
        selected_config: firmware.config,
        selected_delta: firmware.delta,
        selected_same_config: firmware.same_config,
        selected_version: firmware.version,
    }
    const app_settings = []
    if (Core.Settings.useTor) app_settings.push('tor')
    if (Core.Settings.useProxy) app_settings.push('proxy')
    if (Core.Settings.enableTestnet) app_settings.push('testnet')
    if (Core.Settings.usePersonalNode) app_settings.push('electrum_server')
    segmentation.app_settings = app_settings.join(',')
    if (device.type === 1) {
        segmentation.brand = 'Blockstream'
        if (device.versionInfo) {
            segmentation.model = device.versionInfo.BOARD_TYPE
        }
        segmentation.firmware = device.version
        segmentation.connection = 'USB'
    }
    return segmentation
}

function segmentationShareTransaction(account, { method = 'copy' } = {}) {
    const segmentation = segmentationSession(account.context)
    segmentation.method = method
    return segmentation;
}

function segmentationWalletLogin(context, { method }) {
    const segmentation = segmentationSession(context)
    segmentation.method = method
    return segmentation
}

function accountNetwork(account) {
    if (!account) return undefined
    if (account.amp2) {
        return account.context.mainnet ? 'liquid-amp2' : 'testnet-liquid-amp2'
    }
    const network = account.network
    if (network.electrum) {
        return network.id
    }
    return 'legacy-' + network.id
}

function segmentationSubAccount(account) {
    const segmentation = segmentationSession(account.context)
    segmentation.account_type = account.type
    segmentation.account_network = accountNetwork(account)
    return segmentation
}

function segmentationLightning(context, { invoice_type } = {}) {
    const segmentation = segmentationSession(context)
    segmentation.account_type = 'lightning'
    segmentation.account_network = context.mainnet ? 'greenlight-mainnet' : 'greenlight-testnet'
    if (invoice_type) segmentation.invoice_type = invoice_type
    return segmentation
}

function segmentationReceiveAddress(account, type, { method = 'copy' } = {}) {
    const segmentation = segmentationSubAccount(account)
    segmentation.type = type
    segmentation.media = 'text'
    segmentation.method = method
    return segmentation
}

function segmentationLightningReceiveAddress(context, { method = 'copy' } = {}) {
    const segmentation = segmentationLightning(context)
    segmentation.type = 'invoice'
    segmentation.media = 'text'
    segmentation.method = method
    return segmentation
}

function segmentationLightningTransaction(context) {
    return segmentationLightning(context, { invoice_type: 'bolt11' })
}

function segmentationTransaction(account, { address_input, transaction_type, with_memo }) {
    const segmentation = segmentationSubAccount(account)
    segmentation.address_input = address_input // [paste, scan, bip21]
    segmentation.transaction_type = transaction_type // [send, sweep, bump]
    segmentation.with_memo = with_memo
    return segmentation
}

function segmentationWalletActive(context) {
    const segmentation = segmentationSession(context)
    let accounts_funded = 0
    const visible_accounts = UtilJS.accounts(context)
    const accounts_types = new Set
    for (const account of visible_accounts) {
        const key = account.network.liquid ? account.network.policyAsset : 'btc'
        accounts_types.add(account.type)
        if (account.json.satoshi && Object.values(account.json.satoshi).some(satoshi => satoshi > 0)) {
            accounts_funded ++
        }
    }
    segmentation.wallet_funded = accounts_funded > 0
    segmentation.accounts_funded = accounts_funded
    segmentation.accounts = visible_accounts.length
    segmentation.accounts_types = Array.from(accounts_types).join(',')
    return segmentation
}

function segmentationSwap(context, { to, from } = {}) {
    const segmentation = segmentationSession(context)
    if (to) segmentation.to = to
    if (from) segmentation.from = from
    return segmentation
}
