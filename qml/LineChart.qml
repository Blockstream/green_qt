import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes

Page {
    required property url iconSource

    id: root
    implicitWidth: 300
    implicitHeight: 160

    ChartPriceService {
        id: priceSource
    }

    Timer {
        running: true
        interval: 10000
        repeat: true
        triggeredOnStart: true
        onTriggered: priceSource.refresh()
    }

    property color fillColor: Qt.rgba(0.0, 0.737, 1.0, 0.2) // top gradient color

    property bool loading: root.pairCount === 0
    property int selectedIndex: 0
    property bool showRangeButtons: true
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

    readonly property bool isFlatSeries: { const s = root.seriesRef; return s && s.length > 0 && !(s[0] instanceof Array) }
    readonly property var pairCount: { const s = root.seriesRef; return s ? (root.isFlatSeries ? Math.floor(s.length / 2) : s.length) : 0 }
    function pairAt(i) { const s = root.seriesRef; return root.isFlatSeries ? [s[i * 2], s[i * 2 + 1]] : s[i] }
    readonly property real firstPrice: {
        if (root.pairCount <= 0) return NaN
        const p = root.pairAt(0)
        return Number(p[1])
    }
    readonly property real lastPrice: {
        const n = root.pairCount
        if (n <= 0) return NaN
        const p = root.pairAt(n - 1)
        return Number(p[1])
    }
    readonly property real percentChange: {
        const a = root.firstPrice; const b = root.lastPrice;
        return (isFinite(a) && isFinite(b) && a !== 0) ? ((b - a) / a) * 100.0 : 0
    }
    function formatPercent(p) { return (p >= 0 ? '+' : '') + Number(p).toFixed(2) + '%'; }
    function formatCurrency(v, currency = 'USD') {
        if (!isFinite(v)) return '--'
        const abs = Math.abs(Number(v))
        const intPart = Math.trunc(abs)
        const fracPart = Math.round((abs - intPart) * 100)
        const intStr = String(intPart).replace(/\B(?=(\d{3})+(?!\d))/g, '.')
        const fracStr = (fracPart < 10 ? '0' : '') + String(fracPart)
        const sign = v < 0 ? '-' : ''
        return `${sign}${intStr},${fracStr} ${currency}`
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

    background: Rectangle {
        radius: 4
        color: '#161921'
        border.width: 1
        border.color: '#1F222A'
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
            const py = (1.0 - sy) * chartArea.height
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
        return d + ` L ${chartArea.plotWidth} ${chartArea.height} L 0 ${chartArea.height} Z`
    }

    header: Pane {
        background: null
        padding: 12
        contentItem: RowLayout {
            spacing: 8
            Image {
                visible: root.iconSource !== ""
                source: root.iconSource
                sourceSize.width: 28
                sourceSize.height: 28
                width: 28
                height: 28
                fillMode: Image.PreserveAspectFit
                mipmap: true
            }
            Label {
                Layout.fillWidth: true
                text: root.title
                font.pixelSize: 18
                font.weight: 600
                color: "#ffffff"
                opacity: 0.95
            }
            ColumnLayout {
                visible: !root.loading
                Layout.alignment: Qt.AlignVCenter
                spacing: 4
                RowLayout {
                    spacing: 4
                    Layout.alignment: Qt.AlignRight
                    Label {
                    text: root.formatPercent(root.percentChange)
                        font.pixelSize: 14
                        font.weight: 600
                        color: root.percentChange >= 0 ? "#00D084" : "#FF4D4F"
                    }
                    Image {
                        source: root.percentChange >= 0 ? 'qrc:/svg3/Arrow_price_up.svg' : 'qrc:/svg3/Arrow_price_down.svg'
                        width: 14
                        height: 14
                        sourceSize.width: 14
                        sourceSize.height: 14
                        fillMode: Image.PreserveAspectFit
                    }
                }
                Label {
                    // Last price
                    text: root.formatCurrency(root.lastPrice, 'USD')
                    font.pixelSize: 14
                    font.weight: 600
                    color: "#ffffff"
                    opacity: 1.0
                }
            }
        }
    }

    contentItem: Item {
        anchors.fill: parent
        anchors.topMargin: (header?.height ?? 0) + 12
        anchors.bottomMargin: (footer?.height ?? 0) + 12
        Item {
            id: chartArea
            anchors.fill: parent
            property int axisWidth: 48
            readonly property int plotWidth: width - axisWidth

            BusyIndicator {
                id: initial_spinner
                running: initial_spinner.visible
                visible: root.loading
                width: 60
                height: 60
                anchors.centerIn: parent
                anchors.leftMargin: chartArea.axisWidth + (chartArea.plotWidth - width) / 2
            }

            // Grid lines and labels
            Repeater {
                model: root.loading ? 0 : 6
                delegate: Item {
                    required property int index
                    width: chartArea.width
                    height: 1
                    // position from top with 5% padding top/bottom
                    readonly property real _pad: 0.05
                    readonly property real _t: _pad + (index / 5) * (1 - 2 * _pad)
                    y: _t * chartArea.height
                    z: 0
                    // grid line
                    Rectangle {
                        x: chartArea.axisWidth
                        width: chartArea.plotWidth
                        height: 1
                        color: '#3D3D3D'
                        opacity: 0.5
                        z: 0
                    }
                    // label at left gutter
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        x: 0
                        width: chartArea.axisWidth - 6
                        horizontalAlignment: Text.AlignRight
                        color: '#A0A0A0'
                        font.pixelSize: 12
                        z: 2
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

            // Chart paths
            Shape {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.leftMargin: chartArea.axisWidth
                antialiasing: true
                layer.enabled: true
                layer.samples: 4
                z: 1

                ShapePath {
                    strokeWidth: 0
                    fillGradient: LinearGradient {
                        x1: 0; y1: 0
                        x2: 0; y2: chartArea.height
                        GradientStop { position: 0.0; color: root.fillColor }
                        GradientStop { position: 1.0; color: Qt.rgba(0.0, 0.737, 1.0, 0.0) }
                    }
                    PathSvg { path: buildAreaPath }
                }

                ShapePath {
                    strokeColor: '#00BCFF'
                    strokeWidth: 1.5
                    fillColor: "transparent"
                    joinStyle: ShapePath.RoundJoin
                    capStyle: ShapePath.RoundCap
                    PathSvg { path: root.buildSmoothPath }
                }
            }
        }
    }

    footer: Pane {
        visible: root.showRangeButtons && !root.loading
        padding: 12
        background: null
        contentItem: RowLayout {
            spacing: 0
            HSpacer {
            }
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
                }
            }
            HSpacer {
            }
        }
    }

    component RangeButton: AbstractButton {
        id: button
        checkable: true
        leftPadding: 14
        rightPadding: 14
        topPadding: 4
        bottomPadding: 4
        background: Rectangle {
            radius: button.background.height / 2
            color: button.checked ? '#262626' : 'transparent'
            border.width: 0
        }
        contentItem: Label {
            text: button.text
            color: button.checked ? '#FFFFFF' : '#A0A0A0'
            font.pixelSize: 12
            font.weight: 400
        }
    }
}
