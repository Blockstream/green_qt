import QtQuick
import QtTest
import Blockstream.Green

GreenTestCase {
    name: "tst_linechart"

    function test_coreComputedProperties() {
        const context = Qt.createQmlObject('import Blockstream.Green 1.0; Context {}', this)
        const component = Qt.createComponent("../../qml/LineChart.qml")
        verify(component.status === Component.Ready, component.errorString())

        const chart = component.createObject(this, {
            context: context,
            width: 500,
            height: 300
        })
        verify(chart !== null)

        compare(chart.loading, false)
        compare(chart.userCurrency, "usd")
        verify(chart.pairCount > 0, `pairCount: ${chart.pairCount}`)
        compare(chart.dynamicVerticalGridLinesCount, chart.verticalGridLinesCount)

        const b = chart.bounds
        verify(b.xMin <= b.xMax, `xMin ${b.xMin} > xMax ${b.xMax}`)
        verify(b.yMin <= b.yMax, `yMin ${b.yMin} > yMax ${b.yMax}`)

        compare(chart.formatPercent(1.2), "+1.20%")
        compare(chart.formatCompact(1500), "1.5k")
        verify(chart.formatDateTick(1700000000).length > 0, "formatDateTick returned empty string")

        chart.width = 180
        verify(chart.dynamicVerticalGridLinesCount <= 3, `dynamicVerticalGridLinesCount: ${chart.dynamicVerticalGridLinesCount}`)

        chart.selectedIndex = 1
        verify(chart.pairCount > 0, `pairCount: ${chart.pairCount}`)
        verify(chart.seriesRef.length >= 4, `seriesRef.length: ${chart.seriesRef.length}`)

        verify(chart.nearestIndexForPlotX(0) >= 0, `nearestIndexForPlotX(0): ${chart.nearestIndexForPlotX(0)}`)
        verify(chart.nearestIndexForPlotX(chart.width) >= 0, `nearestIndexForPlotX(width): ${chart.nearestIndexForPlotX(chart.width)}`)

        chart.destroy()
        context.destroy()
    }
}
