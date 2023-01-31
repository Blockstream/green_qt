import QtQuick
import QtQuick.Controls

ScriptAction {
    property StackView stackView
    default property Component component
    script: stackView.push(component)
}
