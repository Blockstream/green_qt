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
    }
    id: self
    visible: self.session
    headerItem: RowLayout {
        Label {
            Layout.alignment: Qt.AlignCenter
            color: '#FFF'
            font.capitalization: Font.AllUppercase
            font.pixelSize: 12
            font.weight: 400
            opacity: 0.6
            text: 'Bitcoin ' + qsTrId('id_network_fee')
        }
        HSpacer {
            Layout.minimumHeight: 28
        }
    }
    contentItem: RowLayout {
        spacing: 10
        ColumnLayout {
            Rate {
                color: '#FF0000'
                name: qsTrId('id_fast')
                rate: estimates.fees[3] ?? 0
                time: qsTrId('id_1030_minutes')
            }
            Rate {
                color: '#E99A00'
                name: qsTrId('id_medium')
                rate: estimates.fees[12] ?? 0
                time: qsTrId('id_2_hours')
            }
            Rate {
                color: '#128E2D'
                name: qsTrId('id_slow')
                rate: estimates.fees[24] ?? 0
                time: qsTrId('id_4_hours')
            }
            VSpacer {
            }
        }
    }

    component Rate: RowLayout {
        required property color color
        required property string name
        required property real rate
        required property string time
        Layout.fillHeight: false
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
            text: rate.name + ' (' + Math.round(rate.rate / 100) / 10 + ' sat/vbyte)'
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
