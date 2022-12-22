function segmentationNetwork(network) {
    const segmentation = {}
    segmentation.network
        = network.liquid ? 'liquid'
        : network.mainnet ? 'mainnet'
        : 'testnet'
    segmentation.security
        = network.electrum ? 'singlesig'
        : 'multisig'
    return segmentation
}

function segmentationOnBoard({ flow, network, security }) {
    const segmentation = {}
    if (flow) segmentation.flow = flow
    if (network) segmentation.network = network
    if (security) segmentation.security = security
    return segmentation
}

function segmentationSession(wallet) {
    if (!wallet) return {}
    const segmentation = segmentationNetwork(wallet.network)
    const app_settings = []
    if (Settings.useTor) app_settings.push('tor')
    if (Settings.useProxy) app_settings.push('proxy')
    if (Settings.enableTestnet) app_settings.push('testnet')
    if (Settings.usePersonalNode) app_settings.push('electrum_server')
    if (Settings.enableSPV) app_settings.push('spv')
    segmentation.app_settings = app_settings.join(',')
    if (wallet.device instanceof JadeDevice) {
        segmentation.brand = 'Blockstream'
        segmentation.model = wallet.device.versionInfo.BOARD_TYPE
        segmentation.firmware = wallet.device.version
        segmentation.connection = 'USB'
    }
    if (wallet.device instanceof LedgerDevice) {
        segmentation.brand = 'Ledger'
        segmentation.model
            = wallet.device.type === Device.LedgerNanoS ? 'Ledger Nano S'
            : wallet.device.type === Device.LedgerNanoX ? 'Ledger Nano X'
            : 'Unknown'
        segmentation.firmware = wallet.device.appVersion
        segmentation.connection = 'USB'
    }
    return segmentation
}

function segmentationFirmwareUpdate(device, firmware) {
    const segmentation = {
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

function segmentationShareTransaction(account, { method = 'copy' } = {}) {
    const segmentation = segmentationSession(account.wallet)
    segmentation.method = method
    return segmentation;
}

function segmentationWalletLogin(wallet, { method }) {
    const segmentation = segmentationSession(wallet)
    segmentation.method = method
    return segmentation
}

function segmentationSubAccount(account) {
    const segmentation = segmentationSession(account.wallet)
    segmentation.account_type = account.type
    return segmentation
}

function segmentationReceiveAddress(account, type) {
    const segmentation = segmentationSubAccount(account)
    segmentation.type = type
    segmentation.media = 'text'
    segmentation.method = 'copy'
    return segmentation
}

function segmentationTransaction(account, { address_input, transaction_type, with_memo }) {
    const segmentation = segmentationSubAccount(account)
    segmentation.address_input = address_input // [paste, scan, bip21]
    segmentation.transaction_type = transaction_type // [send, sweep, bump]
    segmentation.with_memo = with_memo
    return segmentation
}

function segmentationWalletActive(wallet) {
    const segmentation = segmentationSession(wallet)
    let accounts_funded = 0
    const accounts_types = new Set
    const key = wallet.network.liquid ? wallet.network.policyAsset : 'btc'
    for (let i = 0; i < wallet.accounts.length; ++i) {
        const account = wallet.accounts[i]
        accounts_types.add(account.type)
        if (account.json.satoshi[key] > 0 || Object.keys(account.json.satoshi).length > 1) {
            accounts_funded ++
        }
    }
    segmentation.wallet_funded = accounts_funded > 0
    segmentation.accounts_funded = accounts_funded
    segmentation.accounts = wallet.accounts.length
    segmentation.accounts_types = Array.from(accounts_types).join(',')
    return segmentation
}
