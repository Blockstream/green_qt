import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

RowLayout {
    property Balance balance

    spacing: 16

    Image {
        sourceSize.width: 32
        sourceSize.height: 32
        source: balance.asset.icon || 'assets/svg/generic_icon_30p.svg'
        width: 32
    }

    ColumnLayout {
        Label {
            Layout.fillWidth: true
            text: balance.asset.name
            font.pixelSize: 14
            elide: Label.ElideRight
        }

        Label {
            visible: 'entity' in balance.asset.data
            Layout.fillWidth: true
            opacity: 0.5
            text: balance.asset.data.entity ? balance.asset.data.entity.domain : 'xxx'
            elide: Label.ElideRight
        }
    }

    Label {
        text: balance.displayAmount
    }
}
