import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

ColumnLayout {
    property var mnemonic
    property int count: 4

    readonly property bool complete: {
        let i = 0;
        for (; i < repeater.count; i++) {
            if (!repeater.itemAt(i).matching) break;
        }
        return i === count;
    }

    function reset() {
        const indexes = [...Array(mnemonic.length).keys()];
        const result = [];
        while (result.length < count) {
            const remove = indexes.length * Math.random();
            const [index] = indexes.splice(remove, 1);
            indexes.splice(Math.max(0, remove - 2), mnemonic.length === 24 ? 4 : 2);
            result.push(index);
        }
        repeater.model = result.sort((a, b) => a - b).map(index => ({ index, word: mnemonic[index] }));
    }
    Component.onCompleted: reset()

    spacing: 16
    VSpacer {
    }
    Label {
        Layout.alignment: Qt.AlignHCenter
        text: qsTrId('id_check_your_backup')
        font.pixelSize: 20
    }
    Repeater {
        id: repeater
        RowLayout {
            Layout.fillWidth: false
            Layout.fillHeight: false
            Layout.alignment: Qt.AlignHCenter
            property bool matching: modelData.word === word_field.text
            spacing: 16
            Label {
                width: 80
                text: modelData.index + 1
                enabled: word_field.enabled
                horizontalAlignment: Label.AlignRight
            }
            TextField {
                id: word_field
                width: 150
                enabled: (index === 0 || repeater.itemAt(index - 1).matching) && !matching
                onEnabledChanged: if (enabled) word_field.forceActiveFocus()
            }
            Image {
                source: 'qrc:/svg/check.svg'
                sourceSize.width: 32
                sourceSize.height: 32
                opacity: matching ? 1 : 0
                Behavior on opacity { OpacityAnimator { } }
            }
        }
    }
    VSpacer {
    }
}
