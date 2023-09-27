import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    property alias leftItem: left_pane.contentItem
    property alias centerItem: center_pane.contentItem
    property alias rightItem: right_pane.contentItem
    id: self
    background: null
    header: Pane {
        background: null
        padding: 0
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
                implicitWidth: header_layout.width / 2 - left_pane.implicitWidth - center_pane.implicitWidth / 2
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
            Item {
                implicitWidth: header_layout.width / 2 - right_pane.implicitWidth - center_pane.implicitWidth / 2
            }
            Pane {
                id: right_pane
                background: null
                padding: 0
            }
        }
    }
}
