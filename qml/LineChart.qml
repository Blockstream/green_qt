import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes

Page {
    property url iconSource: 'qrc:/svg/btc.svg'
    property Context context

    id: root

    ChartPriceService {
        id: priceSource
        currency: root.userCurrency
    }

    Convert {
        id: priceConvert
        context: root.context
        input: ({ btc: '1' })
        unit: root.context ? root.context.primarySession.unit : 'btc'
    }

    readonly property string userCurrency: {
        if (!context || !context.primarySession) return 'usd'
        const session = context.primarySession
        const settings = session.settings
        if (settings && settings.pricing && settings.pricing.currency) {
            return settings.pricing.currency.toLowerCase()
        }
        return 'usd'
    }

    onContextChanged: {
        if (context) {
            priceSource.refresh()
        }
    }

    Timer {
        running: true
        interval: 10000
        repeat: true
        triggeredOnStart: true
        onTriggered: priceSource.refresh()
    }

    title: qsTr('Bitcoin Price')

    property color fillColor: Qt.rgba(0.0, 0.737, 1.0, 0.2) 
    property bool loading: root.pairCount === 0
    property int selectedIndex: 0
    property bool showRangeButtons: true
    property int horizontalGridLinesCount: 6
    property int verticalGridLinesCount: 5
    readonly property int dynamicVerticalGridLinesCount: {
        if (width < 200) return Math.min(3, verticalGridLinesCount)
        if (width < 300) return Math.min(4, verticalGridLinesCount)
        if (width < 400) return Math.min(5, verticalGridLinesCount)
        return verticalGridLinesCount
    }
    readonly property var bounds: {
        let xMin = Number.POSITIVE_INFINITY
        let xMax = Number.NEGATIVE_INFINITY
        let yMin = Number.POSITIVE_INFINITY
        let yMax = Number.NEGATIVE_INFINITY
        const n = root.pairCount
        for (let i = 0; i < n; i++) {
            const p = root.pairAt(i)
            const x = p[0]
            const y = p[1]
            if (x < xMin) xMin = x
            if (x > xMax) xMax = x
            if (y < yMin) yMin = y
            if (y > yMax) yMax = y
        }
        if (!isFinite(xMin) || !isFinite(xMax)) {
            xMin = 0; xMax = 1
        }
        if (!isFinite(yMin) || !isFinite(yMax)) {
            yMin = 0; yMax = 1
        }
        if (xMin === xMax) xMax = xMin + 1
        if (yMin === yMax) yMax = yMin + 1
        return { xMin, xMax, yMin, yMax }
    }
    readonly property var seriesRef: {
        switch (root.selectedIndex) {
            case 0: return priceSource.pricesDay
            case 1: return priceSource.pricesWeek
            case 2: return priceSource.pricesMonth
            case 3: return priceSource.pricesYear
            case 4: return priceSource.pricesFiveYears
        }
        return []
    }

    Component.onCompleted: chartArea.startReveal()
    onSelectedIndexChanged: chartArea.startReveal()

    readonly property bool isFlatSeries: { const s = root.seriesRef; return s && s.length > 0 && !(s[0] instanceof Array) }
    readonly property var pairCount: { const s = root.seriesRef; return s ? (root.isFlatSeries ? Math.floor(s.length / 2) : s.length) : 0 }
    function pairAt(i) { const s = root.seriesRef; return root.isFlatSeries ? [s[i * 2], s[i * 2 + 1]] : s[i] }
    readonly property real firstPrice: {
        if (root.pairCount <= 0) return NaN
        const p = root.pairAt(0)
        return Number(p[1])
    }
    readonly property real lastPrice: {
        const dailySeries = priceSource.pricesDay
        if (!dailySeries || dailySeries.length === 0) return NaN
        const isFlat = !(dailySeries[0] instanceof Array)
        const n = isFlat ? Math.floor(dailySeries.length / 2) : dailySeries.length
        if (n <= 0) return NaN
        const p = isFlat ? [dailySeries[(n - 1) * 2], dailySeries[(n - 1) * 2 + 1]] : dailySeries[n - 1]
        return Number(p[1])
    }
    readonly property real percentChange: {
        const a = root.firstPrice; const b = root.lastPrice;
        return (isFinite(a) && isFinite(b) && a !== 0) ? ((b - a) / a) * 100.0 : 0
    }
    function formatPercent(p) { return (p >= 0 ? '+' : '') + Number(p).toFixed(2) + '%'; }
    function formatCurrency(v, currency = null) {
        if (!isFinite(v)) return '--'
        const userCurr = currency || root.userCurrency.toUpperCase()
        const abs = Math.abs(Number(v))
        const intPart = Math.trunc(abs)
        const fracPart = Math.round((abs - intPart) * 100)
        const intStr = String(intPart).replace(/\B(?=(\d{3})+(?!\d))/g, '.')
        const fracStr = (fracPart < 10 ? '0' : '') + String(fracPart)
        const sign = v < 0 ? '-' : ''
        return `${sign}${intStr},${fracStr} ${userCurr}`
    }
    function formatCompact(v) {
        if (!isFinite(v)) return '--'
        const n = Math.abs(Number(v))
        const sign = v < 0 ? '-' : ''
        if (n >= 1e9) return `${sign}${(n/1e9).toFixed(1)}B`
        if (n >= 1e6) return `${sign}${(n/1e6).toFixed(1)}M`
        if (n >= 1e3) return `${sign}${(n/1e3).toFixed(1)}k`
        return `${sign}${Math.round(n)}`
    }
    function _coerceMillis(timestamp) {
        const numericTimestamp = Number(timestamp)
        return numericTimestamp > 1e12 ? numericTimestamp : numericTimestamp * 1000
    }
    function _pad2(value) { return value < 10 ? '0' + value : '' + value }
    function formatDateTick(timestamp) {
        if (!isFinite(timestamp)) return ''
        const milliseconds = _coerceMillis(timestamp)
        const dateObj = new Date(milliseconds)
        const locale = Qt.locale()
        switch (root.selectedIndex) {
        case 0: // 1D
            return _pad2(dateObj.getHours()) + ':' + _pad2(dateObj.getMinutes())
        case 1: // 1W
        case 2: // 1M
            return _pad2(dateObj.getDate()) + ' ' + locale.monthName(dateObj.getMonth(), Locale.ShortFormat)
        case 3: // 1Y
        case 4: // 5Y
            return locale.monthName(dateObj.getMonth(), Locale.ShortFormat) + ' ' + dateObj.getFullYear()
        }
        return dateObj.toLocaleDateString()
    }
    function formatDate(timestamp) {
        if (!isFinite(timestamp)) return ''
        const milliseconds = _coerceMillis(timestamp)
        const dateObj = new Date(milliseconds)
        const locale = Qt.locale()
        return _pad2(dateObj.getDate()) + ' ' + locale.monthName(dateObj.getMonth(), Locale.ShortFormat) + ' ' + dateObj.getFullYear()
    }
    function formatTime(timestamp) {
        if (!isFinite(timestamp)) return ''
        const milliseconds = _coerceMillis(timestamp)
        const dateObj = new Date(milliseconds)        
        // Only round to hour for weekly (1) and monthly (2) charts
        if (root.selectedIndex === 1 || root.selectedIndex === 2) {
            const roundedDate = new Date(milliseconds)
            roundedDate.setMinutes(0, 0, 0)
            return _pad2(roundedDate.getHours()) + ':00'
        }
        // Keep original precision for daily chart (0)
        return _pad2(dateObj.getHours()) + ':' + _pad2(dateObj.getMinutes())
    }
    readonly property var scaledPoints: {
        const arr = []
        const dx = bounds.xMax - bounds.xMin
        const dy = bounds.yMax - bounds.yMin
        const n = root.pairCount
        for (let i = 0; i < n; i++) {
            const p = pairAt(i)
            const sx = (p[0] - bounds.xMin) / dx
            const sy = (p[1] - bounds.yMin) / dy
            const px = sx * chartArea.plotWidth
            const py = (1.0 - sy) * chartArea.plotHeight
            arr.push({ x: px, y: py })
        }
        return arr
    }
    readonly property string buildSmoothPath: {
        const pts = root.scaledPoints
        if (pts.length < 2) return ''
        let d = `M ${pts[0].x} ${pts[0].y}`
        const n = pts.length
        for (let i = 0; i < n - 1; i++) {
            const p0 = i === 0 ? pts[i] : pts[i - 1]
            const p1 = pts[i]
            const p2 = pts[i + 1]
            const p3 = i + 2 < n ? pts[i + 2] : pts[i + 1]
            const tension = 1.0
            const c1x = p1.x + (p2.x - p0.x) / 6 * tension
            const c1y = p1.y + (p2.y - p0.y) / 6 * tension
            const c2x = p2.x - (p3.x - p1.x) / 6 * tension
            const c2y = p2.y - (p3.y - p1.y) / 6 * tension
            d += ` C ${c1x} ${c1y}, ${c2x} ${c2y}, ${p2.x} ${p2.y}`
        }
        return d
    }
    readonly property string buildAreaPath: {
        const d = root.buildSmoothPath
        if (!d) return ''
        return d + ` L ${chartArea.plotWidth} ${chartArea.plotHeight} L 0 ${chartArea.plotHeight} Z`
    }

    function nearestIndexForPlotX(plotX) {
        const pts = root.scaledPoints
        const n = pts.length
        if (!n) return -1
        let bestIndex = 0
        let bestDist = Math.abs(pts[0].x - plotX)
        for (let i = 1; i < n; i++) {
            const d = Math.abs(pts[i].x - plotX)
            if (d < bestDist) {
                bestDist = d
                bestIndex = i
            }
        }
        return bestIndex
    }

    leftPadding: 24
    rightPadding: 24
    topPadding: 0
    bottomPadding: 0
    spacing: 8
    background: Rectangle {
        radius: 4
        color: '#181818'
        border.width: 1
        border.color: '#262626'
    }

    header: Pane {
        background: null
        leftPadding: 24
        rightPadding: 24
        bottomPadding: 0
        topPadding: 12
        contentItem: RowLayout {
            spacing: 8
            Image {
                Layout.preferredHeight: 24
                Layout.preferredWidth: 24
                visible: root.iconSource !== ''
                source: root.iconSource
                fillMode: Image.PreserveAspectFit
                mipmap: true
            }
            Label {
                visible: parent.width > 220
                Layout.fillWidth: true
                Layout.minimumWidth: 60
                Layout.maximumWidth: parent.width - 180
                text: root.title
                font.pixelSize: 18
                font.weight: 600
                color: '#FFF'
                opacity: 0.95
                elide: Text.ElideRight
            }
            Item {
                visible: parent.width <= 180 || (parent.width - 180) <= 80
                Layout.fillWidth: true
            }
            ColumnLayout {
                visible: !root.loading
                Layout.alignment: Qt.AlignRight
                Layout.minimumWidth: 80
                Layout.maximumWidth: 120
                Layout.preferredWidth: 120
                spacing: 4
                RowLayout {
                    spacing: 4
                    Layout.alignment: Qt.AlignRight
                    Label {
                        text: root.formatPercent(root.percentChange)
                        font.pixelSize: 14
                        font.weight: 600
                        color: root.percentChange >= 0 ? '#00C60D' : '#FF0000'
                        Layout.minimumWidth: 50
                    }
                    Image {
                        source: root.percentChange >= 0 ? 'qrc:/svg3/Arrow_price_up.svg' : 'qrc:/svg3/Arrow_price_down.svg'
                        width: 14
                        height: 14
                        sourceSize.width: 14
                        sourceSize.height: 14
                        fillMode: Image.PreserveAspectFit
                        Layout.minimumWidth: 14
                    }
                }
                Label {
                    // Last price
                    text: priceConvert.fiat.available ? priceConvert.fiat.label : '--'
                    font.pixelSize: 14
                    font.weight: 600
                    color: '#ffffff'
                    opacity: 1.0
                    Layout.alignment: Qt.AlignRight
                    elide: Text.ElideRight
                }
            }
        }
    }

    contentItem: Item {
        id: chartArea
        property int axisWidth: root.width < 250 ? 0 : 48
        property int axisHeight: 20
        readonly property int plotWidth: chartArea.width - chartArea.axisWidth
        readonly property int plotHeight: chartArea.height - chartArea.axisHeight
        property real revealProgress: 0

        function startReveal() {
            reveal_anim.stop()
            chartArea.revealProgress = 0
            reveal_anim.start()
        }

        NumberAnimation on revealProgress {
            id: reveal_anim
            from: 0
            to: 1
            duration: 1000
            easing.type: Easing.OutCubic
        }

        BusyIndicator {
            id: initial_spinner
            running: initial_spinner.visible
            visible: root.loading
            width: 60
            height: 60
            anchors.centerIn: parent
            anchors.leftMargin: chartArea.axisWidth + (chartArea.plotWidth - width) / 2
        }

        Repeater {
            model: root.loading ? 0 : root.horizontalGridLinesCount
            delegate: Item {
                required property int index
                width: chartArea.width
                height: 1
                readonly property real _pad: 0.05
                readonly property real _t: _pad + (index / (root.horizontalGridLinesCount - 1)) * (1 - 2 * _pad)
                y: _t * chartArea.plotHeight
                Rectangle {
                    x: chartArea.axisWidth
                    width: chartArea.plotWidth
                    height: 1
                    color: '#3D3D3D'
                    opacity: 0.5
                }
                Label {
                    visible: root.width >= 250
                    anchors.verticalCenter: parent.verticalCenter
                    x: 0
                    width: chartArea.axisWidth - 6
                    horizontalAlignment: Text.AlignRight
                    color: '#A0A0A0'
                    font.pixelSize: 12
                    elide: Text.ElideRight
                    rightPadding: 4
                    text: {
                        const b = root.bounds
                        const pad = 0.05
                        const t = pad + (index / 5) * (1 - 2 * pad)
                        const val = Number(b.yMax) - t * (Number(b.yMax) - Number(b.yMin))
                        return root.formatCompact(val)
                    }
                }
            }
        }

        Item {
            id: chartPlot
            x: chartArea.axisWidth
            y: 0
            width: Math.max(0, chartArea.plotWidth * chartArea.revealProgress)
            height: chartArea.plotHeight
            clip: true

            Shape {
                anchors.fill: parent
                antialiasing: true
                layer.enabled: true
                layer.samples: 4

                ShapePath {
                    strokeWidth: 0
                    fillGradient: LinearGradient {
                        x1: 0; y1: 0
                        x2: 0; y2: chartArea.plotHeight
                        GradientStop { position: 0.0; color: Qt.rgba(0.0, 0.75, 1.0, 0.35) }
                        GradientStop { position: 0.15; color: Qt.rgba(0.0, 0.65, 0.95, 0.25) }
                        GradientStop { position: 0.4; color: Qt.rgba(0.0, 0.55, 0.9, 0.12) }
                        GradientStop { position: 0.7; color: Qt.rgba(0.0, 0.45, 0.85, 0.04) }
                        GradientStop { position: 1.0; color: Qt.rgba(0.0, 0.4, 0.8, 0.0) }
                    }
                    PathSvg { path: buildAreaPath }
                }

                ShapePath {
                    id: price_shape_path
                    strokeColor: '#00BCFF'
                    strokeWidth: 1.5
                    fillColor: 'transparent'
                    joinStyle: ShapePath.RoundJoin
                    capStyle: ShapePath.RoundCap
                    PathSvg { path: root.buildSmoothPath }
                }
            }
        }


        Item {
            anchors.fill: parent
            visible: !root.loading
            Repeater {
                model: root.dynamicVerticalGridLinesCount
                delegate: Item {
                    required property int index
                    width: 1
                    height: chartArea.plotHeight
                    readonly property real _pad: 0.05
                    readonly property real _t: _pad + (index / (root.dynamicVerticalGridLinesCount - 1)) * (1 - 2 * _pad)
                    x: chartArea.axisWidth + _t * chartArea.plotWidth
                    y: 0
                    Repeater {
                        model: Math.floor(parent.height / 8)
                        delegate: Rectangle {
                            width: 1
                            height: 4
                            x: -0.5
                            y: index * 8
                            color: '#3D3D3D'
                            opacity: 0.5
                        }
                    }
                }
            }

            Repeater {
                model: root.dynamicVerticalGridLinesCount
                delegate: Item {
                    required property int index
                    width: 1; height: 1
                    readonly property real _pad: 0.05
                    readonly property real _t: _pad + (index / (root.dynamicVerticalGridLinesCount - 1)) * (1 - 2 * _pad)
                    readonly property real _xPix: chartArea.axisWidth + _t * chartArea.plotWidth
                    readonly property real _xVal: Number(root.bounds.xMin) + _t * (Number(root.bounds.xMax) - Number(root.bounds.xMin))
                    Label {
                        x: _xPix - width / 2
                        y: chartArea.plotHeight + 4
                        text: root.formatDateTick(_xVal)
                        color: '#A0A0A0'
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        width: Math.min(80, chartArea.plotWidth / root.dynamicVerticalGridLinesCount)
                    }
                }
            }
        }

        Item {
            id: hoverLayer
            anchors.fill: parent
            visible: !root.loading
            HoverHandler {
                id: hover
            }
            readonly property bool active: hover.hovered
            readonly property real rawX: hover.hovered ? hover.point.position.x : 0
            readonly property real plotX: Math.min(chartArea.plotWidth, Math.max(0, rawX - chartArea.axisWidth))
            readonly property int idx: active ? root.nearestIndexForPlotX(plotX) : -1
            readonly property var pt: (idx >= 0 && idx < root.scaledPoints.length) ? root.scaledPoints[idx] : null
            readonly property var pointData: (idx >= 0 && idx < root.pairCount) ? root.pairAt(idx) : null

            Item {
                visible: hoverLayer.active && hoverLayer.pt !== null
                x: chartArea.axisWidth + hoverLayer.plotX - 0.5
                y: 0
                width: 0
                height: chartArea.plotHeight
                Rectangle {
                    width: 1
                    height: hoverLayer.pt?.y ?? 0
                    y: 0
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.0) }
                        GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.15) }
                        GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.5) }
                    }
                }
                Rectangle {
                    width: 1
                    height: hoverLayer.pt ? (chartArea.plotHeight - hoverLayer.pt.y) : 0
                    y: hoverLayer.pt?.y ?? 0
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.5) }
                        GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.15) }
                        GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
                    }
                }
            }

            Item {
                visible: hoverLayer.active && hoverLayer.pt !== null
                x: chartArea.axisWidth + (hoverLayer.pt?.x ?? 0)
                y: hoverLayer.pt?.y ?? 0
                width: 0
                height: 0

                Rectangle {
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    radius: 10
                    color: 'transparent'
                    border.width: 1.5
                    border.color: '#00BCFF'
                    opacity: 0

                    SequentialAnimation on opacity {
                        running: hoverLayer.active && hoverLayer.pt !== null
                        loops: Animation.Infinite
                        NumberAnimation { from: 0.8; to: 0; duration: 1000; easing.type: Easing.OutQuad }
                        PauseAnimation { duration: 200 }
                    }

                    SequentialAnimation on scale {
                        running: hoverLayer.active && hoverLayer.pt !== null
                        loops: Animation.Infinite
                        NumberAnimation { from: 0.5; to: 1.5; duration: 1000; easing.type: Easing.OutQuad }
                        PauseAnimation { duration: 200 }
                    }
                }
                Rectangle {
                    anchors.centerIn: parent
                    width: 8
                    height: 8
                    radius: 4
                    color: '#00BCFF'
                    border.width: 2
                    border.color: '#181818'
                }
            }

            Rectangle {
                visible: hoverLayer.active && hoverLayer.pt !== null
                color: '#222222'
                radius: 4
                border.width: 1
                border.color: '#333333'
                anchors.horizontalCenter: undefined
                x: {
                    if (hoverLayer.pt === null) return 0
                    const tooltipX = chartArea.axisWidth + hoverLayer.pt.x + 8
                    const rightEdge = chartArea.width - width
                    if (tooltipX > rightEdge) {
                        return Math.max(0, chartArea.axisWidth + hoverLayer.pt.x - width - 8)
                    }
                    return Math.min(rightEdge, tooltipX)
                }
                y: {
                    if (hoverLayer.pt === null) return 0
                    const tooltipY = hoverLayer.pt.y - height - 8
                    if (tooltipY < 0) {
                        return Math.min(chartArea.plotHeight - height, hoverLayer.pt.y + 8)
                    }
                    return Math.max(0, tooltipY)
                }
                property int _pad: 10
                width: tipContent.implicitWidth + _pad * 2
                height: tipContent.implicitHeight + _pad * 2

                ColumnLayout {
                    id: tipContent
                    x: parent._pad
                    y: parent._pad
                    spacing: 4
                    RowLayout {
                        spacing: 8
                        Label {
                            text: hoverLayer.pointData ? root.formatDate(hoverLayer.pointData[0]) : ''
                            color: '#A0A0A0'
                            font.pixelSize: 11
                        }
                        Label {
                            visible: root.selectedIndex < 3
                            text: hoverLayer.pointData ? root.formatTime(hoverLayer.pointData[0]) : ''
                            color: '#A0A0A0'
                            font.pixelSize: 11
                        }
                    }
                    Label {
                        text: hoverLayer.pointData ? root.formatCurrency(Number(hoverLayer.pointData[1])) : ''
                        color: '#FFFFFF'
                        font.pixelSize: 12
                        font.weight: 600
                    }
                }
            }
        }
    }

    footer: Pane {
        background: null
        visible: root.showRangeButtons && !root.loading
        leftPadding: 24
        rightPadding: 24
        bottomPadding: 12
        topPadding: 0
        contentItem: RowLayout {
            spacing: 0
            HSpacer {
            }
            RowLayout {
                id: buttonContainer
                spacing: 4
                Layout.alignment: Qt.AlignHCenter

                readonly property real optimalButtonWidth: 42
                readonly property real minButtonWidth: 28
                readonly property real totalOptimalWidth: 5 * optimalButtonWidth + 4 * 4 // 5 buttons + 4 gaps
                readonly property real availableWidth: parent.width - 24
                readonly property bool needsResize: availableWidth < totalOptimalWidth
                readonly property real buttonWidth: needsResize ? Math.max(minButtonWidth, Math.max(0, availableWidth - 4 * 4) / 5) : optimalButtonWidth
                
                Repeater {
                    model: [
                        { text: qsTr('1D'), index: 0 },
                        { text: qsTr('1W'), index: 1 },
                        { text: qsTr('1M'), index: 2 },
                        { text: qsTr('1Y'), index: 3 },
                        { text: qsTr('5Y'), index: 4 }
                    ]
                    delegate: RangeButton {
                        onClicked: root.selectedIndex = index
                        checked: root.selectedIndex === index
                        text: modelData.text
                        needsResize: buttonContainer.needsResize
                        buttonWidth: buttonContainer.buttonWidth
                    }
                }
            }
            HSpacer {
            }
        }
    }

    component RangeButton: AbstractButton {
        id: button
        checkable: true
        property bool needsResize: false
        property real buttonWidth: 42
        
        leftPadding: needsResize ? Math.max(4, buttonWidth / 4) : 14
        rightPadding: needsResize ? Math.max(4, buttonWidth / 4) : 14
        topPadding: 4
        bottomPadding: 4
        
        width: needsResize ? buttonWidth : implicitWidth
        implicitWidth: needsResize ? buttonWidth : 42
        
        background: Rectangle {
            radius: button.background.height / 2
            color: button.checked ? '#262626' : 'transparent'
            border.width: 0
        }
        contentItem: Label {
            text: button.text
            color: button.checked ? '#FFFFFF' : '#A0A0A0'
            font.pixelSize: needsResize ? Math.max(10, Math.min(12, buttonWidth / 4)) : 12
            font.weight: 400
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
}
