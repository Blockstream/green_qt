import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

AbstractButton {
    background: null
    contentItem: RowLayout {
        spacing: 5
        Image {
            source: 'qrc:/svg2/back.svg'
        }
        Label {
            font.family: 'SF Compact Display'
            font.pixelSize: 14
            font.weight: 600
            text: qsTrId('id_back')
        }
    }
}
