import Blockstream.Green.Core 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.13

Button {
    id: self
    required property string location
    property int count: 0
    property bool isCurrent: {
        if (Settings.collapseSideBar) {
            if (navigation.location === location) return true
            return navigation.location.startsWith(location + '/')
        } else {
            return navigation.location === location
        }
    }
    property bool busy: false
    property bool ready: false
    topPadding: 8
    bottomPadding: 8
    leftPadding: 16
    rightPadding: 16
    topInset: 0
    leftInset: 0
    rightInset: 0
    bottomInset: 0

    Layout.fillWidth: true
    onClicked: if (location) navigation.go(location)
    icon.width: 24
    icon.height: 24
    background: Rectangle {
        visible: self.isCurrent || self.hovered
        color: self.hovered ? constants.c600 : constants.c500
        radius: 4
    }
    contentItem: RowLayout {
        spacing: constants.s1
        Image {
            source: self.icon.source
            sourceSize.width: self.icon.width
            sourceSize.height: self.icon.height
        }
        Label {
            visible: !Settings.collapseSideBar
            text: self.text
            elide: Label.ElideMiddle
            Layout.fillWidth: true
            ToolTip.text: self.text
            ToolTip.visible: truncated && self.hovered
            ToolTip.delay: 1000
            rightPadding: 16
            font.styleName: 'Regular'
        }
        BusyIndicator {
            visible: !Settings.collapseSideBar && self.busy
            running: visible
            padding: 0
            Layout.minimumWidth: 16
            Layout.maximumWidth: 16
            Layout.maximumHeight: 16
        }
        Label {
            visible: !Settings.collapseSideBar && count > 0
            text: count
            color: '#444444'
            font.pixelSize: 12
            font.styleName: 'Medium'
            horizontalAlignment: Label.AlignHCenter
            leftPadding: 6
            rightPadding: 6
            background: Rectangle {
                color: 'white'
                radius: 4
            }
        }
    }

    LeftArrowToolTip {
        parent: self
        text: self.text
        font: self.font
        visible: Settings.collapseSideBar && self.hovered
    }
}
