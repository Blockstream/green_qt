import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Layouts 1.12

Image {
    property Asset asset
    property real size: 32
    source: asset.icon || 'qrc:/svg/generic_icon_30p.svg'
    Layout.preferredHeight: size
    Layout.preferredWidth: size
    height: size
    width: size
    fillMode: Image.PreserveAspectFit
    mipmap: true
}
