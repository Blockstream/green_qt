import QtQuick
import QtTest
import Blockstream.Green.Core as Core
import "../../qml/analytics.js" as Analytics

TestCase {
    name: "tst_analytics"

    readonly property var contextMixed: ({
        mainnet: true,
        accounts: [
            { hidden: false, type: "p2wpkh", network: { mainnet: true, liquid: false, electrum: true }, json: { satoshi: { btc: 0 } } },
            { hidden: false, type: "2of2", network: { mainnet: true, liquid: true, electrum: false, policyAsset: "lbtc" }, json: { satoshi: { lbtc: 10 } } }
        ]
    })

    readonly property var contextMainnet: ({
        mainnet: true,
        accounts: [
            { hidden: false, type: "p2wpkh", network: { mainnet: true, liquid: false, electrum: true }, json: { satoshi: { btc: 0 } } }
        ]
    })

    readonly property var contextLiquid: ({
        mainnet: true,
        accounts: [
            { hidden: false, type: "2of2", network: { mainnet: true, liquid: true, electrum: false, policyAsset: "lbtc" }, json: { satoshi: { lbtc: 1 } } }
        ]
    })

    readonly property var contextTestnet: ({
        mainnet: false,
        accounts: [
            { hidden: false, type: "p2wpkh", network: { mainnet: false, liquid: false, electrum: true }, json: { satoshi: { btc: 0 } } }
        ]
    })

    readonly property var contextTestnetMixed: ({
        mainnet: false,
        accounts: [
            { hidden: false, type: "p2wpkh", network: { mainnet: false, liquid: false, electrum: true }, json: { satoshi: { btc: 0 } } },
            { hidden: false, type: "2of2", network: { mainnet: false, liquid: true, electrum: false }, json: { satoshi: { lbtc: 1 } } }
        ]
    })

    readonly property var contextHidden: ({
        mainnet: true,
        accounts: [
            { hidden: false, type: "p2wpkh", network: { mainnet: true, liquid: false, electrum: true }, json: { satoshi: { btc: 0 } } },
            { hidden: true, type: "2of2", network: { mainnet: true, liquid: true, electrum: false }, json: { satoshi: { lbtc: 10 } } }
        ]
    })

    readonly property var singlesigAccount: ({
        context: contextMixed,
        type: "p2wpkh",
        network: { id: "electrum-bitcoin", electrum: true, mainnet: true, liquid: false }
    })

    function init() {
        Core.Settings.useTor = false
        Core.Settings.useProxy = false
        Core.Settings.enableTestnet = true
        Core.Settings.usePersonalNode = true
    }

    function test_segmentationNetworkWithoutContextReportsDesktopSegment() {
        compare(Analytics.segmentationNetwork(null).segment, "Desktop")
    }

    function test_segmentationNetworkReportsWalletNetworksAndSecurity_data() {
        return [
            { tag: "mainnet mixed", context: contextMixed, wallet_networks: "mainnet-mixed", security: "single-multi" },
            { tag: "mainnet", context: contextMainnet, wallet_networks: "mainnet", security: "singlesig" },
            { tag: "liquid", context: contextLiquid, wallet_networks: "liquid", security: "multisig" },
            { tag: "testnet", context: contextTestnet, wallet_networks: "testnet", security: "singlesig" },
            { tag: "testnet mixed", context: contextTestnetMixed, wallet_networks: "testnet-mixed", security: "single-multi" },
            { tag: "hidden accounts ignored", context: contextHidden, wallet_networks: "mainnet", security: "singlesig" }
        ]
    }

    function test_segmentationNetworkReportsWalletNetworksAndSecurity(row) {
        const seg = Analytics.segmentationNetwork(row.context)
        compare(seg.wallet_networks, row.wallet_networks)
        compare(seg.security, row.security)
    }

    function test_segmentationOnBoardCopiesFlowNetworkAndSecurity() {
        const seg = Analytics.segmentationOnBoard({ flow: "create", network: "mainnet", security: "singlesig" })
        compare(seg.segment, "Desktop")
        compare(seg.flow, "create")
        compare(seg.network, "mainnet")
        compare(seg.security, "singlesig")
    }

    function test_segmentationSessionReportsEnabledAppSettings() {
        const seg = Analytics.segmentationSession(contextMixed)
        verify(seg.app_settings.indexOf("testnet") >= 0)
        verify(seg.app_settings.indexOf("electrum_server") >= 0)
    }

    function test_segmentationSessionReportsJadeDeviceDetails() {
        const context = {
            mainnet: true,
            accounts: contextMixed.accounts,
            device: { type: 1, versionInfo: { BOARD_TYPE: "JADE_V2" }, version: "1.0.0" }
        }
        const seg = Analytics.segmentationSession(context)
        compare(seg.brand, "Blockstream")
        compare(seg.model, "JADE_V2")
        compare(seg.connection, "USB")
    }

    function test_segmentationPromoAddsPromoIdAndScreen() {
        const seg = Analytics.segmentationPromo(contextMixed, { id: "promo-1" }, "home")
        compare(seg.promo_id, "promo-1")
        compare(seg.screen, "home")
    }

    function test_segmentationWalletLoginAddsLoginMethod() {
        const seg = Analytics.segmentationWalletLogin(contextMixed, { method: "pin" })
        compare(seg.method, "pin")
    }

    function test_segmentationFirmwareUpdateReportsSelectedFirmwareAndDevice() {
        const firmware = { config: "std", delta: true, same_config: false, version: "2.0.0" }
        const device = { type: 1, versionInfo: { BOARD_TYPE: "JADE" }, version: "1.9.0" }
        const seg = Analytics.segmentationFirmwareUpdate(device, firmware)
        compare(seg.segment, "Desktop")
        compare(seg.selected_version, "2.0.0")
        compare(seg.brand, "Blockstream")
    }

    function test_segmentationSubAccountUsesNetworkIdForSinglesigAccount() {
        const seg = Analytics.segmentationSubAccount(singlesigAccount)
        compare(seg.segment, "Desktop")
        compare(seg.account_network, "electrum-bitcoin")
    }

    function test_segmentationReceiveAddressDefaultsToCopiedText() {
        const seg = Analytics.segmentationReceiveAddress(singlesigAccount, "p2wpkh")
        compare(seg.type, "p2wpkh")
        compare(seg.media, "text")
        compare(seg.method, "copy")
    }

    function test_segmentationTransactionAddsInputTypeAndMemo() {
        const seg = Analytics.segmentationTransaction(singlesigAccount, {
            address_input: "paste",
            transaction_type: "send",
            with_memo: true
        })
        compare(seg.address_input, "paste")
        compare(seg.transaction_type, "send")
        compare(seg.with_memo, true)
    }

    function test_segmentationShareTransactionAddsShareMethod() {
        const seg = Analytics.segmentationShareTransaction(singlesigAccount, { method: "qr" })
        compare(seg.method, "qr")
    }

    function test_segmentationSwapAddsSourceAndDestinationAssets() {
        const seg = Analytics.segmentationSwap(contextMixed, { from: "btc", to: "lbtc" })
        compare(seg.from, "btc")
        compare(seg.to, "lbtc")
    }

    function test_segmentationWalletActiveSummarizesVisibleFundedAccounts() {
        const seg = Analytics.segmentationWalletActive(contextMixed)
        compare(seg.wallet_funded, true)
        compare(seg.accounts, 2)
        verify(seg.accounts_types.indexOf("p2wpkh") >= 0)
        verify(seg.accounts_types.indexOf("2of2") >= 0)
    }
}
