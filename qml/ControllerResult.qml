import QtQuick 2.13
import QtQuick.Controls 2.5

Connections {
    default property Component component
    property string status
    property StackView stackView
    target: controller
    onResultChanged: {
        if (result.status === status) {
            stackView.push(component)
        }
    }
}
