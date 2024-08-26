import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

Page {
    default property alias contentItemData: flickable.contentItemData
    property alias leftItem: left_pane.contentItem
    property alias centerItem: center_pane.contentItem
    property alias rightItem: right_pane.contentItem
    property alias footerItem: footer_pane.contentItem
    StackView.onActivated: self.forceActiveFocus()
    id: self
    background: null
    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0
    footer: Pane {
        id: footer_pane
        background: null
        padding: self.padding
        leftPadding: self.padding
        rightPadding: self.padding
        bottomPadding: self.padding
        topPadding: 20
    }
    header: Pane {
        background: null
        leftPadding: self.padding
        rightPadding: self.padding
        topPadding: self.padding
        bottomPadding: 20
        contentItem: RowLayout {
            spacing: 0
            id: header_layout
            Pane {
                id: left_pane
                background: null
                padding: 0
                contentItem: BackButton {
                    onClicked: self.StackView.view.pop()
                    visible: self.StackView.index > 0
                    enabled: self.StackView.status === StackView.Active
                }
            }
            Item {
                Layout.preferredWidth: Math.max(UtilJS.effectiveWidth(right_pane) - UtilJS.effectiveWidth(left_pane), 0)
            }
            HSpacer {
            }
            Pane {
                id: center_pane
                background: null
                padding: 0
                contentItem: Label {
                    color: '#FFF'
                    font.pixelSize: 14
                    font.weight: 600
                    text: self.title
                }
            }
            HSpacer {
            }
            Item {
                Layout.preferredWidth: Math.max(UtilJS.effectiveWidth(left_pane) - UtilJS.effectiveWidth(right_pane), 0)
            }
            Pane {
                id: right_pane
                background: null
                padding: 0
            }
        }
    }
    contentItem: VFlickable {
        id: flickable
    }
}
