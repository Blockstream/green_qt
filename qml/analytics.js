.pragma library

.import "util.js" as UtilJS

function segmentationNetwork(context) {
    const segmentation = {
        segment: 'Desktop',
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

function segmentationSession(Settings, context) {
    const segmentation = segmentationNetwork(context)
    const app_settings = []
    if (Settings.useTor) app_settings.push('tor')
    if (Settings.useProxy) app_settings.push('proxy')
    if (Settings.enableTestnet) app_settings.push('testnet')
    if (Settings.usePersonalNode) app_settings.push('electrum_server')
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

function segmentationPromo(Settings, context, promo, screen) {
    const segmentation = segmentationSession(Settings, context)
    segmentation.promo_id = promo.id
    segmentation.screen = screen
    return segmentation
}

function segmentationFirmwareUpdate(Settings, device, firmware) {
    const segmentation = {
        segment: 'Desktop',
        selected_config: firmware.config,
        selected_delta: firmware.delta,
        selected_same_config: firmware.same_config,
        selected_version: firmware.version,
    }
    const app_settings = []
    if (Settings.useTor) app_settings.push('tor')
    if (Settings.useProxy) app_settings.push('proxy')
    if (Settings.enableTestnet) app_settings.push('testnet')
    if (Settings.usePersonalNode) app_settings.push('electrum_server')
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

function segmentationShareTransaction(Settings, account, { method = 'copy' } = {}) {
    const segmentation = segmentationSession(Settings, account.context)
    segmentation.method = method
    return segmentation;
}

function segmentationWalletLogin(Settings, context, { method }) {
    const segmentation = segmentationSession(Settings, context)
    segmentation.method = method
    return segmentation
}

function segmentationSubAccount(Settings, account) {
    const segmentation = segmentationSession(Settings, account.context)
    segmentation.account_type = account.type
    return segmentation
}

function segmentationLightning(Settings, context, { invoice_type } = {}) {
    const segmentation = segmentationSession(Settings, context)
    segmentation.account_type = 'lightning'
    if (invoice_type) segmentation.invoice_type = invoice_type
    return segmentation
}

function segmentationReceiveAddress(Settings, account, type, { method = 'copy' } = {}) {
    const segmentation = segmentationSubAccount(Settings, account)
    segmentation.type = type
    segmentation.media = 'text'
    segmentation.method = method
    return segmentation
}

function segmentationLightningReceiveAddress(Settings, context, { method = 'copy' } = {}) {
    const segmentation = segmentationLightning(Settings, context)
    segmentation.type = 'invoice'
    segmentation.media = 'text'
    segmentation.method = method
    return segmentation
}

function segmentationLightningTransaction(Settings, context) {
    return segmentationLightning(Settings, context, { invoice_type: 'bolt11' })
}

function segmentationTransaction(Settings, account, { address_input, transaction_type, with_memo }) {
    const segmentation = segmentationSubAccount(Settings, account)
    segmentation.address_input = address_input // [paste, scan, bip21]
    segmentation.transaction_type = transaction_type // [send, sweep, bump]
    segmentation.with_memo = with_memo
    return segmentation
}

function segmentationWalletActive(Settings, context) {
    const segmentation = segmentationSession(Settings, context)
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

function segmentationSwap(Settings, context, { to, from } = {}) {
    const segmentation = segmentationSession(Settings, context)
    if (to) segmentation.to = to
    if (from) segmentation.from = from
    return segmentation
}
