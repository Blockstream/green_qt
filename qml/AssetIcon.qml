import Blockstream.Green 0.1
import QtQuick 2.12

Image {
    property Asset asset
    property real size: 32
    source: asset.icon || '/svg/generic_icon_30p.svg'
    sourceSize.height: size
    sourceSize.width: size
}
