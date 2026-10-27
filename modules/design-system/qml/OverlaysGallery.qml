import Blockstream.Controls
import Blockstream.Theme
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    required property Colors colors
    property string lastAction: 'No dialog action selected'

    id: self
    Layout.minimumWidth: 0
    spacing: 24
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4
        UiLabel {
            Layout.fillWidth: true
            text: 'UiDialog / UiDrawer'
            typography: Theme.typography.titleSSemibold
            color: self.colors.textPrimary
            wrapMode: Text.Wrap
        }
        UiLabel {
            Layout.fillWidth: true
            text: 'Dialog and drawer surfaces with 32px padding and a scrim. Dialogs supply a title and Close header; callers own body content and actions. Try Escape, outside clicks, and both drawer edges.'
            typography: Theme.typography.bodyS
            color: self.colors.textSubtle
            wrapMode: Text.Wrap
        }
    }
    Flow {
        Layout.fillWidth: true
        spacing: 12
        UiButton {
            text: 'Open dialog'
            variant: UiButton.Secondary
            colors: self.colors
            onClicked: example_dialog.open()
        }
        UiButton {
            text: 'Right drawer'
            variant: UiButton.Secondary
            colors: self.colors
            onClicked: {
                example_drawer.edge = Qt.RightEdge
                example_drawer.open()
            }
        }
        UiButton {
            text: 'Left drawer'
            variant: UiButton.Secondary
            colors: self.colors
            onClicked: {
                example_drawer.edge = Qt.LeftEdge
                example_drawer.open()
            }
        }
    }
    UiToggle {
        id: long_content
        text: 'Long drawer content'
        colors: self.colors
    }
    UiLabel {
        text: self.lastAction
        typography: Theme.typography.bodyS
        color: self.colors.textSubtle
    }

    UiDialog {
        id: example_dialog
        title: 'Example dialog'
        colors: self.colors
        accessibleId: 'gallery_example_dialog'
        onAccepted: self.lastAction = 'Dialog accepted'
        onRejected: self.lastAction = 'Dialog rejected'
        contentItem: ColumnLayout {
            spacing: 20
            UiLabel {
                Layout.fillWidth: true
                text: 'Caller-owned dialog content. This shell is centered over the window and grows with its content.'
                typography: Theme.typography.bodyM
                color: self.colors.textSubtle
                wrapMode: Text.Wrap
            }
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8
                UiButton {
                    Layout.alignment: Qt.AlignHCenter
                    text: 'Confirm'
                    colors: self.colors
                    onClicked: example_dialog.accept()
                }
                UiButton {
                    Layout.alignment: Qt.AlignHCenter
                    text: 'Cancel'
                    variant: UiButton.Tertiary
                    colors: self.colors
                    onClicked: example_dialog.reject()
                }
            }
        }
    }
    UiDrawer {
        id: example_drawer
        colors: self.colors
        accessibleId: 'gallery_example_drawer'
        contentItem: Page {
            padding: 0
            spacing: 20
            background: null
            contentItem: Flickable {
                id: drawer_scroll
                clip: true
                contentWidth: width
                contentHeight: drawer_body.implicitHeight
                ScrollIndicator.vertical: ScrollIndicator {}
                ColumnLayout {
                    id: drawer_body
                    width: drawer_scroll.width
                    spacing: 20
                    UiLabel {
                        Layout.fillWidth: true
                        text: 'Caller-owned drawer content. Scrolling and the bottom action are provided by this example, not by UiDrawer.'
                        typography: Theme.typography.bodyM
                        color: self.colors.textSubtle
                        wrapMode: Text.Wrap
                    }
                    Repeater {
                        model: long_content.checked ? 12 : 3
                        UiCard {
                            required property int index
                            Layout.fillWidth: true
                            colors: self.colors
                            contentItem: UiLabel {
                                text: `Content ${index + 1}`
                                typography: Theme.typography.bodyM
                                color: self.colors.textPrimary
                            }
                        }
                    }
                }
            }
            footer: UiButton {
                text: 'Done'
                colors: self.colors
                onClicked: example_drawer.close()
            }
        }
    }
}
