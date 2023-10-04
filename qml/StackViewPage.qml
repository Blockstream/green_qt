import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    property alias leftItem: left_pane.contentItem
    property alias centerItem: center_pane.contentItem
    property alias rightItem: right_pane.contentItem
    id: self
    background: null
    function effectiveWidth(item) {
        return item.visible ? item.width : 0
    }
    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0
    header: Pane {
        background: null
        padding: self.padding
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
                Layout.preferredWidth: Math.max(effectiveWidth(right_pane) - effectiveWidth(left_pane))
            }
            HSpacer {
            }
            Pane {
                id: center_pane
                background: null
                padding: 0
                contentItem: Label {
                    font.family: 'SF Compact Display'
                    font.pixelSize: 14
                    font.weight: 600
                    text: self.title
                }
            }
            HSpacer {
            }
            Item {
                Layout.preferredWidth: Math.max(effectiveWidth(left_pane) - effectiveWidth(right_pane))
            }
            Pane {
                id: right_pane
                background: null
                padding: 0
            }
        }
    }

    component Footer: Pane {
        background: null
        padding: self.padding
    }
}
