import QtQuick
import QtTest
import "../../qml/util.js" as Util

TestCase {
    name: "tst_util"

    readonly property var contextWithArchivedAccounts: ({
        accounts: [
            { hidden: false, pointer: 0, amp0: true, type: "2of2_no_recovery", network: { electrum: false, liquid: true } },
            { hidden: true, pointer: 0, amp0: true, type: "2of2_no_recovery", network: { electrum: false, liquid: true } },
            { hidden: true, pointer: 2, type: "p2wpkh", network: { electrum: false, liquid: false } }
        ]
    })

    function test_flattenMergesArraysAndScalarsSkippingNull() {
        compare(Util.flatten([1, 2], [3], null), [1, 2, 3])
        compare(Util.flatten(5, [6]), [5, 6])
    }

    function test_linkWrapsTextInAnchorPointingToUrl() {
        const out = Util.link("https://example.com", "Example")
        verify(out.indexOf("<a href=\"https://example.com\">Example</a>") >= 0)
    }

    function test_assetIconPrefersExplicitIcon() {
        compare(Util.assetIcon({ icon: "qrc:/x.svg" }), "qrc:/x.svg")
    }

    function test_assetIconUsesNetworkIconForPolicyAsset() {
        compare(Util.assetIcon({ policy: true, networkKey: "liquid" }), "qrc:/svg/liquid.svg")
    }

    function test_assetIconFallsBackToGenericIconForUnknownAsset() {
        compare(Util.assetIcon({ id: "unknown" }), "qrc:/svg/generic_icon_30p.svg")
    }

    function test_iconForMapsBitcoinToBtcIcon() {
        compare(Util.iconFor("bitcoin"), "qrc:/svg/btc.svg")
    }

    function test_networkIconResolvesIconFromNetworkKey() {
        compare(Util.networkIcon({ key: "testnet" }), "qrc:/svg/btc_testnet.svg")
    }

    function test_accountNameIsEmptyForMissingAccount() {
        compare(Util.accountName(null), "")
    }

    function test_accountNameUsesCustomNameWhenSet() {
        compare(Util.accountName({ name: "Primary", mainAccount: false, pointer: 1 }), "Primary")
    }

    function test_accountNameFallsBackToMainAccountLabelForUnnamedMainAccount() {
        compare(Util.accountName({ name: "", mainAccount: true, pointer: 0 }), qsTrId("id_main_account"))
    }

    function test_accountLabelLocalizesAccountType() {
        compare(Util.accountLabel({ type: "2of2" }), qsTrId("id_2of2"))
    }

    function test_accountPolicyLabelIsSinglesigForElectrumNetwork() {
        compare(Util.accountPolicyLabel({ network: { electrum: true } }), qsTrId("id_singlesig"))
    }

    function test_effectiveVisibleIsFalseWhenAnAncestorIsHidden() {
        const root = { visible: true, parent: null }
        const child = { visible: true, parent: root }
        verify(Util.effectiveVisible(child))
        root.visible = false
        verify(!Util.effectiveVisible(child))
    }

    function test_effectiveWidthIsZeroForHiddenItem() {
        compare(Util.effectiveWidth({ visible: true, width: 10 }), 10)
        compare(Util.effectiveWidth({ visible: false, width: 42 }), 0)
    }

    function test_accountsExcludesHiddenAccounts() {
        compare(Util.accounts(contextWithArchivedAccounts).length, 1)
    }

    function test_archivedAccountsExcludesHiddenMainAmpAccountWithoutOtherLiquidMultisig() {
        const archived = Util.archivedAccounts(contextWithArchivedAccounts)
        compare(archived.length, 1)
        compare(archived[0].type, "p2wpkh")
    }

    function test_incognitoMasksDigitsWhenEnabled() {
        compare(Util.incognito(true, "123,45"), "*****")
    }

    function test_incognitoReturnsValueUnchangedWhenDisabled() {
        compare(Util.incognito(false, "abc"), "abc")
    }

    function test_normalizeUnitMapsMicroSignToUbtcAndLowercasesOthers() {
        compare(Util.normalizeUnit("µBTC"), "ubtc")
        compare(Util.normalizeUnit("BTC"), "btc")
    }

    function test_unitReadsPrimarySessionUnit() {
        compare(Util.unit({ primarySession: { unit: "btc" } }), "btc")
    }

    function test_getUnblindingDataKeepsOnlyFullyBlindedInputsAndOutputs() {
        const tx = {
            txhash: "abc",
            type: "incoming",
            inputs: [{ pt_idx: 1, asset_id: "a", satoshi: 1, assetblinder: "b", amountblinder: "c" }, { pt_idx: 2 }],
            outputs: [{ pt_idx: 3, asset_id: "a", satoshi: 2, assetblinder: "d", amountblinder: "e" }]
        }
        const out = Util.getUnblindingData(tx)
        compare(out.version, 0)
        compare(out.txid, "abc")
        compare(out.type, "incoming")
        compare(out.inputs.length, 1)
        compare(out.inputs[0].vin, 1)
        compare(out.inputs[0].asset_id, "a")
        compare(out.inputs[0].satoshi, 1)
        compare(out.inputs[0].assetblinder, "b")
        compare(out.inputs[0].amountblinder, "c")
        compare(out.outputs.length, 1)
        compare(out.outputs[0].vout, 3)
        compare(out.outputs[0].asset_id, "a")
        compare(out.outputs[0].satoshi, 2)
        compare(out.outputs[0].assetblinder, "d")
        compare(out.outputs[0].amountblinder, "e")
    }

    function test_confirmationsIsZeroForUnconfirmedTransaction() {
        compare(Util.confirmations({ block: { block_height: 100 } }, 0), 0)
    }

    function test_confirmationsCountsBlocksIncludingInclusionBlock() {
        compare(Util.confirmations({ block: { block_height: 100 } }, 90), 11)
    }

    function test_transactionIconShowsHourglassWhileUnconfirmed() {
        compare(Util.transactionIcon("sent", 0), "qrc:/icons/hourglass-high.svg")
    }

    function test_transactionIconUsesTypeIconOnceConfirmed() {
        compare(Util.transactionIcon("sent", 2), "qrc:/svg2/tx-sent.svg")
    }

    function test_twoFactorMethodLabelLocalizesMethod() {
        compare(Util.twoFactorMethodLabel("email"), qsTrId("id_email"))
    }

    function test_transactionTypeLabelLocalizesTransactionType_data() {
        return [
            { tag: "incoming with relevant output", data: { type: "incoming", outputs: [{ is_relevant: true }] }, expected: qsTrId("id_received") },
            { tag: "outgoing", data: { type: "outgoing" }, expected: qsTrId("id_sent") },
            { tag: "mixed", data: { type: "mixed" }, expected: qsTrId("id_swap") }
        ]
    }

    function test_transactionTypeLabelLocalizesTransactionType(row) {
        compare(Util.transactionTypeLabel({ data: row.data }), row.expected)
    }

    function test_shuffleKeepsAllElements() {
        const arr = [1, 2, 3, 4]
        const out = Util.shuffle(arr)
        compare(out.length, arr.length)
        compare(out.slice().sort().join(","), arr.slice().sort().join(","))
    }

    function test_csvTimeLabelRoundsSixBlocksToAboutOneHour() {
        compare(Util.csvTimeLabel(6), "~1 " + qsTrId("id_hour"))
    }

    function test_csvLabelAppendsBlockCountToTimeLabel() {
        compare(Util.csvLabel(12), Util.csvTimeLabel(12) + " (12 " + qsTrId("id_blocks") + ")")
    }

    function test_formatFeeRateUsesTwoDecimalsOnLiquid() {
        compare(Util.formatFeeRate(1050, { liquid: true }), "1.05 sat/vbyte")
    }

    function test_formatFeeRateUsesOneDecimalOnBitcoin() {
        compare(Util.formatFeeRate(1050, { liquid: false }), "1.1 sat/vbyte")
    }

    function test_getProviderInitialsUsesFirstLetterOfFirstTwoWords() {
        compare(Util.getProviderInitials("Block Stream"), "BS")
    }

    function test_getProviderInitialsUsesFirstTwoLettersOfSingleWord() {
        compare(Util.getProviderInitials("Al"), "AL")
    }

    function test_colorFromProviderNameIsStableForSameName() {
        verify(Qt.colorEqual(Util.colorFromProviderName("Blockstream"), Util.colorFromProviderName("Blockstream")))
    }

    function test_confirmationTimeIsDashWithoutFullFeeEstimates() {
        compare(Util.confirmationTime(1, null), "-")
    }

    function test_confirmationTimeIsTwoHoursWhenRateIsBelowThreeBlockEstimate() {
        compare(Util.confirmationTime(1, new Array(25).fill(10)), qsTrId("id_2_hours"))
    }

    function test_filterPromoShowsJadePlusPromoWhenAJadePlusWalletExists() {
        const wallets = [{ login: {} }, { login: { device: { type: "jade", board: "JADE_V2" } } }]
        compare(Util.filterPromo(wallets, { id: "x", data: { target: "jadeplus_user" } }), true)
    }

    function test_isJadeV2MatchesV2BoardRevisions() {
        compare(Util.isJadeV2("JADE_V2.1"), true)
    }

    function test_jadeImageUsesJade2AssetForV2Board() {
        compare(Util.jadeImage({ versionInfo: { BOARD_TYPE: "JADE_V2" } }, 1), "qrc:/png/jade2_1.png")
    }

    function test_localizedLabelTranslatesKnownLabel() {
        compare(Util.localizedLabel("locked"), qsTrId("id_locked"))
    }

    function test_localizedLabelKeepsScriptTypeUntranslated() {
        compare(Util.localizedLabel("p2tr"), "p2tr")
    }

    function test_swapNetworkTypeDependsOnNetwork_data() {
        return [
            { tag: "liquid", network: { liquid: true, mainnet: true }, expected: "liquid" },
            { tag: "bitcoin mainnet", network: { liquid: false, mainnet: true }, expected: "mainnet" },
            { tag: "bitcoin testnet", network: { liquid: false, mainnet: false }, expected: null }
        ]
    }

    function test_swapNetworkTypeDependsOnNetwork(row) {
        compare(Util.swapNetworkType(row.network), row.expected)
    }
}
