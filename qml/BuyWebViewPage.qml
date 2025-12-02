import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtWebEngine

StackViewPage {
    signal showTransactions()
    required property string widgetUrl
    id: self
    title: 'Buy Bitcoin'
    rightItem: CloseButton {
        onClicked: self.closeClicked()
    }
    contentItem: Rectangle {
        color: '#181818'
        
        WebEngineView {
            anchors.fill: parent
            url: self.widgetUrl
            
            onNavigationRequested: function(request) {
                const url = request.url.toString()
                
                if (url === "blockstream://redirect/transactions") {
                    request.reject()
                    self.showTransactions()
                } else {
                    request.accept()
                }
            }
        }
    }
}
