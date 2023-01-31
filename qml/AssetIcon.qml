import Blockstream.Green
import QtQuick
import QtQuick.Layouts

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
