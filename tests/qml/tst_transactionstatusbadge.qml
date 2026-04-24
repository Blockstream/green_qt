import QtQuick
import QtTest

GreenTestCase {
    name: "tst_transactionstatusbadge"

    function createBadge(properties) {
        const component = Qt.createComponent("../../qml/TransactionStatusBadge.qml")
        verify(component.status === Component.Ready, component.errorString())
        const badge = component.createObject(this, properties)
        verify(badge !== null)
        return badge
    }

    function test_unconfirmedState() {
        const badge = createBadge({ confirmations: 0, liquid: false })
        compare(badge.completed, false)
        compare(badge.text, qsTrId("id_unconfirmed"))
        compare(badge.visible, true)
        badge.destroy()
    }

    function test_bitcoinPartiallyConfirmed() {
        // No translations are loaded by the runner, so the untranslated id has
        // no %1 placeholder and arg() leaves it unchanged with a warning.
        ignoreWarning('QString::arg: Argument missing: "id_d6_confirmations", 3')
        const badge = createBadge({ confirmations: 3, liquid: false })
        compare(badge.completed, false)
        compare(badge.text, qsTrId("id_d6_confirmations"))
        compare(badge.visible, true)
        badge.destroy()
    }

    function test_completedState() {
        const badge = createBadge({ confirmations: 6, liquid: false })
        compare(badge.completed, true)
        compare(badge.visible, false)
        badge.destroy()
    }

    function test_liquidThreshold() {
        const badge = createBadge({ confirmations: 1, liquid: true })
        compare(badge.completed, false)
        compare(badge.text, qsTrId("id_12_confirmations"))
        badge.confirmations = 2
        compare(badge.completed, true)
        compare(badge.visible, false)
        badge.destroy()
    }
}
