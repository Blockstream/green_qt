import Blockstream.Green 0.1
import QtQuick 2.14
import QtQml 2.14
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.12
import QtQuick.Shapes 1.0

import "util.js" as UtilJS

GTextField {
    id: self
    property Word word
    readonly property bool invalid: word.suggestions.length === 0 && self.text.length > 2

    Connections {
        target: word
        function onSuggestionsChanged() {
            if (suggestionIndex >= word.suggestions.length) suggestionIndex = 0
        }
    }

    enabled: word.enabled
    leftPadding: 40
    Binding on text {
        restoreMode: Binding.RestoreBinding
        when: !activeFocus
        value: word.text
    }
    onTextChanged: {
        if (activeFocus) {
            text = word.update(text.trim());
            if (word.suggestions.length === 1 && text === word.suggestions[0] && suggestionIndex < 0) {
                nextItemInFocusChain().forceActiveFocus()
            }
        }
    }
    Keys.onPressed: {
        if (word.index > 0 && event.key === Qt.Key_Backspace && text === '') {
            nextItemInFocusChain(false).forceActiveFocus();
        }
        if (event.key === Qt.Key_Down) {
            suggestionIndex = (suggestionIndex + 1) >= word.suggestions.length ? 0 : suggestionIndex + 1
        }
        if (event.key === Qt.Key_Up) {
            suggestionIndex = suggestionIndex <= 0 ? word.suggestions.length - 1 : suggestionIndex - 1
        }
        if (event.key === Qt.Key_Tab || event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
            if (word.suggestions.length === 1) {
                text = word.suggestions[0]
            }
            if (suggestionIndex >= 0) {
                text = word.suggestions[suggestionIndex]
            }
            nextItemInFocusChain().forceActiveFocus()
        }
        if (suggestionIndex >= 0 && word.suggestions.length > 1) {
            const y = (suggestions_layout.implicitHeight + suggestions_layout.spacing) / word.suggestions.length * suggestionIndex
            const h = (suggestions_layout.implicitHeight + suggestions_layout.spacing) / word.suggestions.length - suggestions_layout.spacing
            if (y + h > flickable.contentY + flickable.height) {
                flickable.contentY = Math.min(y + h - flickable.height, flickable.contentHeight - flickable.height)
            } else if (y < flickable.contentY) {
                flickable.contentY = Math.max(y, 0)
            }
        } else {
            flickable.contentY = 0
        }
    }
    property int suggestionIndex: -1

    Popup {
        readonly property point scenePosition: {
            popup.visible
            return UtilJS.dynamicScenePosition(self, 0, 0)
        }
        id: popup
        visible: self.activeFocus && (word.suggestions.length > 1 || (word.suggestions.length === 1 && word.suggestions[0] !== self.text) || self.invalid)
        x: scenePosition.x + self.width / 2 - popup.width / 2
        y: scenePosition.y + self.height + constants.s1
        parent: Overlay.overlay
        topPadding: 20
        background: Shape {
            layer.samples: 4
            ShapePath {
                strokeColor: constants.c200
                strokeWidth: 1
                fillColor: constants.c400
                startX: 4
                startY: 8
                PathLine {
                    x: popup.width / 2 - 8
                    y: 8
                }
                PathLine {
                    x: popup.width / 2
                    y: 0
                }
                PathLine {
                    x: popup.width / 2 + 8
                    y: 8
                }
                PathAngleArc {
                    moveToStart: false
                    radiusX: 4
                    radiusY: 4
                    centerX: popup.width - 4
                    centerY: 8 + 4
                    startAngle: -90
                    sweepAngle: 90
                }
                PathAngleArc {
                    moveToStart: false
                    radiusX: 4
                    radiusY: 4
                    centerX: popup.width - 4
                    centerY: popup.height - 4
                    startAngle: 0
                    sweepAngle: 90
                }
                PathAngleArc {
                    moveToStart: false
                    radiusX: 4
                    radiusY: 4
                    centerX: 4
                    centerY: popup.height - 4
                    startAngle: 90
                    sweepAngle: 90
                }
                PathAngleArc {
                    moveToStart: false
                    radiusX: 4
                    radiusY: 4
                    centerX: 4
                    centerY: 8 + 4
                    startAngle: 180
                    sweepAngle: 90
                }
            }
        }

        contentItem: Flickable {
            id: flickable
            clip: true
            implicitWidth: suggestions_layout.implicitWidth
            implicitHeight: Math.min(suggestions_layout.implicitHeight, 200)
            contentWidth: suggestions_layout.implicitWidth
            contentHeight: suggestions_layout.implicitHeight
            ColumnLayout {
                id: suggestions_layout
                spacing: constants.s1
                Label {
                    visible: self.invalid
                    text: qsTrId('id_not_a_valid_word')
                    Layout.fillWidth: true
                }
                Repeater {
                    model: word.suggestions
                    Label {
                        padding: 4
                        background: Item {
                            visible: model.index === suggestionIndex
                            Rectangle {
                                height: parent.height
                                anchors.centerIn: parent
                                width: popup.contentItem.width
                                color: constants.c200
                            }
                        }
                        text: modelData
                        Layout.alignment: Qt.AlignCenter
                    }
                }
            }
        }
        enter: null
        exit: null
    }

    Label {
        anchors.baseline: parent.baseline
        x: 8
        width: 24
        horizontalAlignment: Qt.AlignRight
        text: word.index + 1
        color: self.invalid ? 'red' : 'white'
    }
}
