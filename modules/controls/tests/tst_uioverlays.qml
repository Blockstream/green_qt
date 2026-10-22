import Blockstream.Controls
import Blockstream.Testing
import QtQuick

GreenTestCase {
    id: self
    name: 'tst_uioverlays'
    when: windowShown
    width: 720
    height: 560

    Component {
        id: dialog_component
        UiDialog {
            contentItem: Item { implicitHeight: 100 }
        }
    }
    Component {
        id: drawer_component
        UiDrawer {
            contentItem: Item { implicitHeight: 100 }
        }
    }
    Component {
        id: content_component
        Item {
            implicitWidth: 200
            implicitHeight: 120
        }
    }

    function test_contentRootId_data() {
        return [
            { tag: 'dialog', component: dialog_component, role: Qt.platform.os === 'osx' ? Accessible.Grouping : Accessible.Dialog },
            { tag: 'drawer', component: drawer_component, role: Accessible.Grouping }
        ]
    }

    function test_contentRootId(row) {
        const overlay = createTemporaryObject(row.component, self, { accessibleId: 'original_root' })
        verify(overlay !== null)
        tryCompare(overlay.contentItem.Accessible, 'id', 'original_root')
        compare(overlay.contentItem.Accessible.role, row.role)
        const replacement = createTemporaryObject(content_component, self)
        verify(replacement !== null)
        replacement.Accessible.role = Accessible.Pane
        overlay.contentItem = replacement
        tryCompare(replacement.Accessible, 'id', 'original_root')
        compare(replacement.Accessible.role, row.role)
        overlay.accessibleId = 'replacement_root'
        tryCompare(replacement.Accessible, 'id', 'replacement_root')
        overlay.accessibleId = ''
        tryCompare(replacement.Accessible, 'id', '')
        compare(replacement.Accessible.role, Accessible.Pane)
    }

    function test_drawerContentInsets_data() {
        return [
            { tag: 'left', edge: Qt.LeftEdge },
            { tag: 'right', edge: Qt.RightEdge }
        ]
    }

    function test_drawerContentInsets(row) {
        const drawer = createTemporaryObject(drawer_component, self, { edge: row.edge })
        verify(drawer !== null)
        drawer.open()
        tryCompare(drawer, 'opened', true)
        compare(drawer.contentItem.x, 32)
        compare(drawer.contentItem.y, 32)
        tryVerify(() => drawer.contentItem.width === drawer.width - 64)
        tryVerify(() => drawer.contentItem.height === drawer.height - 64)
        drawer.padding = 16
        tryCompare(drawer.contentItem, 'x', 16)
        tryCompare(drawer.contentItem, 'y', 16)
        tryVerify(() => drawer.contentItem.width === drawer.width - 32)
        tryVerify(() => drawer.contentItem.height === drawer.height - 32)
        drawer.close()
    }
}
