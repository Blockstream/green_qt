import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

WalletHeaderCard {
    readonly property Session session: {
        for (let i = 0; i < self.context.sessions.length; i++) {
            const session = self.context.sessions[i]
            if (!session.network.liquid) return session
        }
        return null
    }

    FeeEstimates {
        id: estimates
        session: self.session
        onFeesChanged: canvas.requestPaint()
    }
    id: self
    visible: self.session
    contentItem: RowLayout {
        spacing: 10
        ColumnLayout {
            Label {
                font.capitalization: Font.AllUppercase
                font.pixelSize: 12
                font.weight: 400
                opacity: 0.6
                text: qsTrId('id_network_fee')
            }
            VSpacer {
            }
            Rate {
                color: '#128E2D'
                name: qsTrId('id_slow')
                rate: estimates.fees[24]
                time: qsTrId('id_4_hours')
            }
            Rate {
                color: '#E99A00'
                name: qsTrId('id_medium')
                rate: estimates.fees[12]
                time: qsTrId('id_2_hours')
            }
            Rate {
                color: '#FF0000'
                name: qsTrId('id_fast')
                rate: estimates.fees[3]
                time: qsTrId('id_1030_minutes')
            }
            VSpacer {
            }
        }
        Canvas {
            Layout.preferredHeight: 80
            Layout.preferredWidth: 120
            id: canvas
            contextType: "2d"
            onPaint: {
                if (estimates.fees.length === 0) return
                let max = 100;
                let i
                for (i = 1; i < estimates.fees.length; i++) {
                    const fee = estimates.fees[i]
                    if (fee > max) max = fee
                }
                const sx = canvas.width / Math.max(1, estimates.fees.length)
                const sy = canvas.height / max
                const ps = []
                for (i = 1; i < estimates.fees.length; i++) {
                    ps.push({ x: sx * i, y: canvas.height - sy * estimates.fees[i] })
                }

                const ctx = canvas.context
                ctx.clearRect(0, 0, canvas.width, canvas.height)
                ctx.moveTo(ps[0].x, ps[0].y)
                ctx.beginPath()
                for (i = 1; i < ps.length; i++) {
                    ctx.lineTo(ps[i].x, ps[i].y)
                }
                ctx.strokeStyle = Qt.alpha('#FFF', 0.4)
                ctx.lineWidth = 1
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(0, canvas.height)
                ctx.lineTo(canvas.width, canvas.height)
                ctx.stroke()

                ctx.beginPath()
                ctx.fillStyle = '#FF0000'
                ctx.moveTo(ps[2].x, ps[2].y)
                ctx.arc(ps[2].x, ps[2].y, 3, 0, Math.PI * 2, false)
                ctx.closePath()
                ctx.fill()

                ctx.beginPath()
                ctx.fillStyle = '#E99A00'
                ctx.moveTo(ps[11].x, ps[11].y)
                ctx.arc(ps[11].x, ps[11].y, 3, 0, Math.PI * 2, false)
                ctx.closePath()
                ctx.fill()

                ctx.beginPath()
                ctx.fillStyle = '#128E2D'
                ctx.moveTo(ps[23].x, ps[23].y)
                ctx.arc(ps[23].x, ps[23].y, 3, 0, Math.PI * 2, false)
                ctx.closePath()
                ctx.fill()
            }
        }
    }

    component Rate: RowLayout {
        required property color color
        required property string name
        required property real rate
        required property string time
        id: rate
        spacing: 0
        Rectangle {
            Layout.alignment: Qt.AlignCenter
            color: rate.color
            implicitHeight: 10
            implicitWidth: 10
            radius: 5
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.leftMargin: 3
            Layout.rightMargin: 7
            font.pixelSize: 12
            font.weight: 400
            text: rate.name + ' (' + Math.round(rate.rate / 10 + 0.5) / 100 + ' sats/btc)'
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            font.pixelSize: 12
            font.weight: 400
            opacity: 0.4
            text: rate.time
        }
        HSpacer {
        }
    }
}
