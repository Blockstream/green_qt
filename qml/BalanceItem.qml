import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

RowLayout {
    property Balance balance

    spacing: 16

    AssetIcon {
        asset: balance.asset
    }

    ColumnLayout {
        Label {
            Layout.fillWidth: true
            text: balance.asset.name
            font.pixelSize: 14
            elide: Label.ElideRight
        }

        Label {
            visible: balance.asset.data.entity
            Layout.fillWidth: true
            opacity: 0.5
            text: balance.asset.data.entity ? balance.asset.data.entity.domain : ''
            elide: Label.ElideRight
        }
    }

    Label {
        text: balance.displayAmount
    }
}
