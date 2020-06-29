import QtQuick 2.13
import QtQuick.Controls 2.5

Connections {
    default property Component component
    property string targetStatus
    property StackView stackView
    target: controller
    function onStatusChanged(status) {
        if (status === targetStatus) {
            stackView.push(component)
        }
    }
}
