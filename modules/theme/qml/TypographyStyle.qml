import QtQuick

QtObject {
    property string family: 'Inter'
    property int pixelSize: 14
    property int weight: Font.Normal
    property real letterSpacing: 0
    property int capitalization: Font.MixedCase
    property real lineHeight: 20

    readonly property font font: Qt.font({
        family: family,
        pixelSize: pixelSize,
        weight: weight,
        letterSpacing: letterSpacing,
        capitalization: capitalization
    })
}
