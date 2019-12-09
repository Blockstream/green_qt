import QtQuick 2.0
import QtQuick.Controls 2.13

ScriptAction {
    property StackView stackView
    default property Component component
    script: stackView.push(component)
}
