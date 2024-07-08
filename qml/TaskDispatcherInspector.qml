import Blockstream.Green
import QtQml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    required property TaskDispatcher dispatcher
    id: self
    clip: true
    padding: 4
    background: Rectangle {
        color: 'black'
        opacity: 0.2
        radius: 4
    }
    contentItem: ListView {
        model: {
            const groups = []
            if (self.dispatcher) {
                for (let i = 0; i < self.dispatcher.groups.length; i++) {
                    const group = self.dispatcher.groups[i]
                    if (group.status !== TaskGroup.Finished) {
                        groups.push(group)
                    }
                }
            }
            return groups
        }
        spacing: 4
        ScrollIndicator.vertical: ScrollIndicator {
        }
        delegate: Pane {
            property TaskGroup group: modelData
            id: group_pane
            clip: true
            width: parent?.width ?? 0
            background: Rectangle {
                radius: 4
                color: {
                    switch (group.status) {
                    case TaskGroup.Ready: return Qt.rgba(1, 1, 1, 0.1)
                    case TaskGroup.Active: return Qt.rgba(1, 1, 0, 0.1)
                    case TaskGroup.Failed: return Qt.rgba(1, 0, 0, 0.1)
                    case TaskGroup.Finished: return Qt.rgba(0, 1, 0, 0.1)
                    }
                }
                border.width: 0.5
                border.color: {
                    switch (group.status) {
                    case TaskGroup.Ready: return Qt.rgba(1, 1, 1, 0.5)
                    case TaskGroup.Active: return Qt.rgba(1, 1, 0, 0.5)
                    case TaskGroup.Failed: return Qt.rgba(1, 0, 0, 0.5)
                    case TaskGroup.Finished: return Qt.rgba(0, 1, 0, 0.5)
                    }
                }
            }
            contentItem: ColumnLayout {
                Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    horizontalAlignment: Label.AlignCenter
                    font.pixelSize: 8
                    font.weight: 400
                    font.styleName: 'Regular'
                    wrapMode: Label.WrapAnywhere
                    text: group_pane?.group.name ?? 'n/a'
                    visible: group_pane?.group.name
                }
                Repeater {
                    model: group.tasks
                    delegate: RowLayout {
                        spacing: 4
                        property Task task: modelData
                        ProgressBar {
                            Layout.maximumWidth: 16
                            indeterminate: task.status === Task.Active
                            value: task.status === Task.Finished ? 1 : 0
                            from: 0
                            to: 1
                            opacity: task.status === Task.Failed ? 0 : 1
                        }
                        Label {
                            text: task.error ? task.type + '\n - error: ' + task.error : task.type
                            font.pixelSize: 10
                            font.weight: 400
                            font.styleName: 'Regular'
                            wrapMode: Label.WrapAnywhere
                        }
                    }
                }
            }
        }
    }
}
