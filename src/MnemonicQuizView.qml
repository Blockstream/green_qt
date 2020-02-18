import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

RowLayout {
    property int count: 4

    property bool complete: {
        let i = 0;
        for (; i < repeater.count; i++) {
            if (!repeater.itemAt(i).matching) break;
        }
        return i === count;
    }

    function reset() {
        const indexes = [...Array(24).keys()];
        const result = [];
        while (result.length < count) {
            const remove = indexes.length * Math.random();
            const [index] = indexes.splice(remove, 1);
            indexes.splice(Math.max(0, remove - 2), 4);
            result.push(index);
        }
        repeater.model = result.sort((a, b) => a - b).map(index => ({ index, word: mnemonic[index] }));
    }

    Label {
        text: qsTr('id_make_sure_you_made_a_proper')
        font.pixelSize: 14
    }

    Column {
        spacing: 16

        Repeater {
            id: repeater

            Row {
                property bool matching: modelData.word === word_field.text

                spacing: 16

                Label {
                    width: 80
                    text: modelData.index + 1
                    enabled: word_field.enabled
                    horizontalAlignment: Label.AlignRight
                    anchors.baseline: word_field.baseline
                }

                TextField {
                    id: word_field
                    width: 150
                    enabled: (index === 0 || repeater.itemAt(index - 1).matching) && !matching
                    onEnabledChanged: if (enabled) word_field.forceActiveFocus()
                }

                Image {
                    anchors.verticalCenter: word_field.verticalCenter
                    source: 'assets/svg/check.svg'
                    sourceSize.width: 32
                    sourceSize.height: 32
                    opacity: matching ? 1 : 0
                    Behavior on opacity { OpacityAnimator { } }
                }
            }
        }
    }
}
