import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "util.js" as UtilJS

Rectangle {
    id: provider_icon
    required property string providerName
    
    property string initials: UtilJS.getProviderInitials(providerName)
    property color iconColor: UtilJS.colorFromProviderName(providerName)
    
    radius: width / 2
    color: iconColor
    
    Label {
        anchors.fill: parent
        topPadding: 1
        horizontalAlignment: Label.AlignHCenter
        verticalAlignment: Label.AlignVCenter
        color: '#FFFFFF'
        font.pixelSize: Math.max(8, provider_icon.width * 0.5)
        font.weight: 600
        text: provider_icon.initials
    }
}

