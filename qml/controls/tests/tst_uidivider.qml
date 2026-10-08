import Blockstream.Controls
import Blockstream.Testing
import Blockstream.Theme
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtTest

GreenTestCase {
    id: self
    name: "tst_uidivider"
    when: windowShown
    width: 300
    height: 200

    Component {
        id: column_component
        ColumnLayout {
            property alias divider: column_divider

            width: 240
            spacing: 8
            Item { implicitHeight: 20 }
            UiDivider {
                id: column_divider
            }
            Item { implicitHeight: 20 }
        }
    }

    Component {
        id: row_component
        RowLayout {
            property alias divider: row_divider

            height: 64
            spacing: 8
            Item { implicitWidth: 20 }
            UiDivider {
                id: row_divider
                orientation: Qt.Vertical
                weight: UiDivider.Bold
            }
            Item { implicitWidth: 20 }
        }
    }

    Component {
        id: focus_component
        Row {
            property alias first: first_button
            property alias second: second_button
            property alias divider: focus_divider

            spacing: 8
            Button {
                id: first_button
                text: "First"
                focusPolicy: Qt.StrongFocus
            }
            UiDivider {
                id: focus_divider
                orientation: Qt.Vertical
                height: 24
            }
            Button {
                id: second_button
                text: "Second"
                focusPolicy: Qt.StrongFocus
            }
        }
    }

    function test_horizontalFillsLayoutWidth() {
        const column = createTemporaryObject(column_component, self)
        verify(column !== null)
        waitForRendering(column)
        compare(column.divider.width, 240)
        compare(column.divider.height, 1)
        column.width = 120
        waitForRendering(column)
        compare(column.divider.width, 120)
        compare(column.divider.height, 1)
    }

    function test_verticalFillsLayoutHeight() {
        const row = createTemporaryObject(row_component, self)
        verify(row !== null)
        waitForRendering(row)
        compare(row.divider.width, 1)
        compare(row.divider.height, 64)
        row.height = 32
        waitForRendering(row)
        compare(row.divider.height, 32)
        compare(row.divider.width, 1)
    }

    function test_weightColors_data() {
        return [
            { tag: "subtle", weight: UiDivider.Subtle, token: "borderSubtle" },
            { tag: "bold", weight: UiDivider.Bold, token: "borderBold" }
        ]
    }

    function test_weightColors(row) {
        const column = createTemporaryObject(column_component, self)
        verify(column !== null)
        column.divider.weight = row.weight
        compare(column.divider.color, Theme.colors[row.token])
        column.divider.colors = Theme.lightColors
        compare(column.divider.color, Theme.lightColors[row.token])
    }

    function test_doesNotTakeFocus() {
        const row = createTemporaryObject(focus_component, self)
        verify(row !== null)
        row.first.forceActiveFocus(Qt.TabFocusReason)
        verify(row.first.activeFocus)
        keyClick(Qt.Key_Tab)
        verify(row.second.activeFocus)
        verify(!row.divider.activeFocus)
        compare(row.divider.activeFocusOnTab, false)
    }

    function test_accessibility() {
        const column = createTemporaryObject(column_component, self)
        verify(column !== null)
        compare(column.divider.Accessible.role, Accessible.Separator)
    }
}
