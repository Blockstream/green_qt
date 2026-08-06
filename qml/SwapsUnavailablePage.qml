import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    id: self
    rightItem: CloseButton {
        onClicked: self.closeClicked()
    }
    footerItem: ColumnLayout {
        LinkButton {
            Layout.alignment: Qt.AlignCenter
            font.pixelSize: 16
            external: true
            text: qsTrId('id_learn_more')
            onClicked: Qt.openUrlExternally('https://help.blockstream.com/blockstream-app/faqs/why-are-swaps-unavailable')
        }
    }
    contentItem: ColumnLayout {
        spacing: 48
        MultiImage {
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 100
            foreground: 'qrc:/svg3/swaps_unavailable.svg'
            width: 128
            height: 128
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12
            Label {
                Layout.fillWidth: true
                color: '#FFFFFF'
                font.pixelSize: 24
                font.weight: 700
                horizontalAlignment: Label.AlignHCenter
                text: 'Swaps Unavailable'
                wrapMode: Label.WordWrap
            }
            Label {
                Layout.fillWidth: true
                Layout.maximumWidth: 360
                Layout.alignment: Qt.AlignHCenter
                color: '#A0A0A0'
                font.pixelSize: 16
                font.weight: 400
                horizontalAlignment: Label.AlignHCenter
                text: 'New swaps are temporarily disabled due to a service interruption. Your funds are safe. We are working to restore functionality.'
                wrapMode: Label.WordWrap
            }
        }
        VSpacer {
        }
    }
}
