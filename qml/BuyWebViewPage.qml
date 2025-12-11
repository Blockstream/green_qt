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
    footer: null
    rightItem: CloseButton {
        onClicked: self.closeClicked()
    }
    contentItem: Item {
        BusyIndicator {
            anchors.centerIn: parent
            running: web_engine_view.loading
            visible: web_engine_view.loading
        }
        WebEngineView {
            id: web_engine_view
            anchors.fill: parent
            anchors.leftMargin: -30
            anchors.rightMargin: -30
            anchors.bottomMargin: -30
            url: self.widgetUrl
            visible: !web_engine_view.loading
            onPermissionRequested: (permission) => {
                permission.deny()
            }
            onNavigationRequested: function(request) {
                const url = request.url.toString()
                if (url === "blockstream://redirect/transactions") {
                    request.reject()
                    self.showTransactions()
                } else {
                    request.accept()
                }
            }
            onContextMenuRequested: (request) => {
                request.accepted = true
            }
            onTooltipRequested: (request) => {
                request.accepted = true
            }
        }
        Rectangle {
            anchors.left: web_engine_view.left
            anchors.right: web_engine_view.right
            anchors.top: web_engine_view.top
            color: '#181818'
            opacity: 0.5
            height: 1
            width: parent.width
        }
    }
}
