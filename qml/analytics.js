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

    for (let i = 0; i < context.accounts.length; ++i) {
        const account = context.accounts[i]
        if (account.hidden) continue
        const network = account.network
        mainnet = mainnet || (network.mainnet && !network.liquid)
        liquid = liquid || (network.mainnet && network.liquid)
        testnet = testnet || (!network.mainnet && !network.liquid)
        testnet_liquid = testnet_liquid || (!network.mainnet && network.liquid)
        singlesig = singlesig || network.electrum
        multisig = multisig || !network.electrum
    }

    if (mainnet && liquid) {
        segmentation.wallet_networks = 'mainnet-mixed'
    } else if (mainnet && !liquid) {
        segmentation.wallet_networks = 'mainnet'
    } else if (!mainnet && liquid) {
        segmentation.wallet_networks = 'liquid'
    }
    if (testnet && testnet_liquid) {
        segmentation.wallet_networks = 'testnet-mixed'
    } else if (testnet && !liquid) {
        segmentation.wallet_networks = 'testnet'
    } else if (!testnet && liquid) {
        segmentation.wallet_networks = 'testnet-liquid'
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
    if (!wallet) return {}
    const segmentation = segmentationNetwork(context)
    const app_settings = []
    if (Settings.useTor) app_settings.push('tor')
    if (Settings.useProxy) app_settings.push('proxy')
    if (Settings.enableTestnet) app_settings.push('testnet')
    if (Settings.usePersonalNode) app_settings.push('electrum_server')
    if (Settings.enableSPV) app_settings.push('spv')
    segmentation.app_settings = app_settings.join(',')
    const device = wallet.context?.device
    if (device instanceof JadeDevice) {
        segmentation.brand = 'Blockstream'
        segmentation.model = device.versionInfo.BOARD_TYPE
        segmentation.firmware = device.version
        segmentation.connection = 'USB'
    }
    if (device instanceof LedgerDevice) {
        segmentation.brand = 'Ledger'
        segmentation.model
            = device.type === Device.LedgerNanoS ? 'Ledger Nano S'
            : device.type === Device.LedgerNanoX ? 'Ledger Nano X'
            : 'Unknown'
        segmentation.firmware = device.appVersion
        segmentation.connection = 'USB'
    }
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
    if (Settings.enableSPV) app_settings.push('spv')
    segmentation.app_settings = app_settings.join(',')
    if (device instanceof JadeDevice) {
        segmentation.brand = 'Blockstream'
        segmentation.model = device.versionInfo.BOARD_TYPE
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
    return segmentation
}

function segmentationReceiveAddress(Settings, account, type) {
    const segmentation = segmentationSubAccount(Settings, account)
    segmentation.type = type
    segmentation.media = 'text'
    segmentation.method = 'copy'
    return segmentation
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
    const accounts_types = new Set
    for (let i = 0; i < context.accounts.length; ++i) {
        const account = context.accounts[i]
        const key = account.network.liquid ? account.network.policyAsset : 'btc'
        accounts_types.add(account.type)
        if (Object.values(account.json.satoshi).filter(satoshi => satoshi > 0).length > 0) {
            accounts_funded ++
        }
    }
    segmentation.wallet_funded = accounts_funded > 0
    segmentation.accounts_funded = accounts_funded
    segmentation.accounts = context.accounts.length
    segmentation.accounts_types = Array.from(accounts_types).join(',')
    return segmentation
}
