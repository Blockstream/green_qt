import Blockstream.Controls
import Blockstream.Theme
import Blockstream.Testing
import QtQuick

GreenTestCase {
    id: self
    name: 'tst_uicombobox'
    when: windowShown
    width: 640
    height: 600
    Component {
        id: combo_component
        UiComboBox {
            model: [
                {
                    label: 'First',
                    code: 10
                },
                {
                    label: 'Second',
                    code: 20
                }
            ]
            textRole: 'label'
            valueRole: 'code'
        }
    }
    function test_keyboardSelectionUsesModelRoles() {
        const combo = createTemporaryObject(combo_component, self)
        compare(combo.currentValue, 10)
        combo.forceActiveFocus()
        keyClick(Qt.Key_Down)
        compare(combo.currentValue, 20)
        compare(combo.currentText, 'Second')
    }

    function test_escapeDismissesPopup() {
        const combo = createTemporaryObject(combo_component, self)
        combo.forceActiveFocus()
        combo.popup.open()
        tryCompare(combo.popup, 'opened', true)
        keyClick(Qt.Key_Escape)
        tryCompare(combo.popup, 'visible', false)
    }

    function test_emptyModelClearsSelection() {
        const combo = createTemporaryObject(combo_component, self)
        combo.model = []
        compare(combo.currentIndex, -1)
    }
    Component {
        id: mutable_model_component
        ListModel {
            ListElement { label: 'First'; alternate: 'One'; code: 10 }
            ListElement { label: 'Second'; alternate: 'Two'; code: 20 }
        }
    }
    function test_modelRoleUpdates() {
        const model = createTemporaryObject(mutable_model_component, self)
        const combo = createTemporaryObject(combo_component, self, {model})
        combo.popup.open()
        tryCompare(combo.popup, 'opened', true)
        const list = combo.popup.contentItem
        tryVerify(() => list.itemAtIndex(0) !== null && list.itemAtIndex(1) !== null)
        model.setProperty(0, 'label', 'Renamed first')
        model.setProperty(1, 'label', 'Renamed second')
        compare(combo.currentText, 'Renamed first')
        compare(list.itemAtIndex(0).text, 'Renamed first')
        compare(list.itemAtIndex(1).text, 'Renamed second')
        combo.textRole = 'alternate'
        compare(list.itemAtIndex(0).text, 'One')
        compare(list.itemAtIndex(1).text, 'Two')
        combo.popup.close()
    }
    function test_stringModel() {
        const combo = createTemporaryObject(combo_component, self, {
            model: ['First', 'Second'], textRole: '', valueRole: ''
        })
        combo.popup.open()
        tryCompare(combo.popup, 'opened', true)
        const list = combo.popup.contentItem
        tryVerify(() => list.itemAtIndex(1) !== null)
        compare(list.itemAtIndex(0).text, 'First')
        compare(list.itemAtIndex(1).text, 'Second')
        verify(waitForRendering(list.itemAtIndex(1)))
        mouseClick(list.itemAtIndex(1))
        compare(combo.currentText, 'Second')
        tryCompare(combo.popup, 'visible', false)
    }
    function test_palettes_data() {
        return [
            { tag: 'light', colors: Theme.lightColors },
            { tag: 'dark', colors: Theme.darkColors }
        ]
    }
    function test_palettes(row) {
        const item = createTemporaryObject(combo_component, self, {colors: row.colors})
        verify(item !== null)
        verify(waitForRendering(item))
    }

    function test_longPopupKeyboardSelection() {
        const model = Array.from({ length: 40 }, (_, index) => ({
            label: 'Option ' + index,
            code: index
        }))
        const combo = createTemporaryObject(combo_component, self, { model })
        combo.forceActiveFocus()
        combo.popup.open()
        tryCompare(combo.popup, 'opened', true)
        for (let index = 0; index < 30; ++index) keyClick(Qt.Key_Down)
        compare(combo.highlightedIndex, 30)
        const list = combo.popup.contentItem
        tryVerify(() => list.contentY > 0)
        keyClick(Qt.Key_Return)
        compare(combo.currentValue, 30)
        tryCompare(combo.popup, 'visible', false)
    }
    function test_disabledSelection() {
        const combo = createTemporaryObject(combo_component, self, {disabled: true})
        mouseClick(combo)
        keyClick(Qt.Key_Down)
        compare(combo.currentValue, 10)
        compare(combo.popup.visible, false)
    }

    function test_clickSelectedRowKeepsCheckmark() {
        const combo = createTemporaryObject(combo_component, self)
        combo.popup.open()
        tryCompare(combo.popup, 'opened', true)
        const list = combo.popup.contentItem
        tryVerify(() => list.itemAtIndex(0) !== null && list.itemAtIndex(1) !== null)
        const first = list.itemAtIndex(0)
        compare(first.checked, true)
        mouseClick(first)
        tryCompare(combo.popup, 'visible', false)
        compare(combo.currentIndex, 0)
        combo.popup.open()
        tryCompare(combo.popup, 'opened', true)
        compare(first.checked, true)
        const second = list.itemAtIndex(1)
        verify(waitForRendering(second))
        mouseClick(second)
        tryCompare(combo.popup, 'visible', false)
        compare(combo.currentIndex, 1)
        combo.popup.open()
        tryCompare(combo.popup, 'opened', true)
        compare(second.checked, true)
        compare(first.checked, false)
        combo.popup.close()
    }
}
