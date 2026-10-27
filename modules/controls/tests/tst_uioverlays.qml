import Blockstream.Controls
import Blockstream.Testing
import QtQuick
import QtQuick.Controls as Controls

GreenTestCase {
    id: self
    name: 'tst_uioverlays'
    when: windowShown
    width: 720
    height: 560

    Component {
        id: dialog_component
        UiDialog {
            property int rejectedCount: 0

            onRejected: ++rejectedCount
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

    function test_dialogClosePolicy_data() {
        return [
            {tag: 'untitled', title: '', policy: Controls.Popup.CloseOnEscape},
            {tag: 'titled', title: 'Dialog title', policy: Controls.Popup.CloseOnPressOutside},
            {tag: 'untitled locked', title: '', policy: Controls.Popup.NoAutoClose},
            {tag: 'titled locked', title: 'Dialog title', policy: Controls.Popup.NoAutoClose}
        ]
    }

    function test_dialogClosePolicy(row) {
        const dialog = createTemporaryObject(dialog_component, self, {
            title: row.title, closePolicy: row.policy
        })
        dialog.open()
        tryCompare(dialog, 'opened', true)
        const close = findItems(dialog.header, item => item instanceof UiIconButton)[0]
        const closable = row.policy !== Controls.Popup.NoAutoClose
        compare(close.visible, closable)
        compare(close.enabled, closable)
        compare(dialog.header.visible, closable || row.title.length > 0)
        dialog.closePolicy = Controls.Popup.NoAutoClose
        verify(!close.visible)
        verify(!close.enabled)
        mouseClick(close)
        compare(dialog.opened, true)
        compare(dialog.rejectedCount, 0)
        dialog.closePolicy = Controls.Popup.CloseOnEscape | Controls.Popup.CloseOnPressOutside
        verify(close.visible)
        verify(close.enabled)
        mouseClick(close)
        tryCompare(dialog, 'visible', false)
        compare(dialog.rejectedCount, 1)
    }

    function test_dialogDismissible_data() {
        return [
            {tag: 'untitled close', title: '', method: 'close'},
            {tag: 'titled close', title: 'Dialog title', method: 'close'},
            {tag: 'untitled escape', title: '', method: 'escape'},
            {tag: 'titled escape', title: 'Dialog title', method: 'escape'},
            {tag: 'untitled outside', title: '', method: 'outside'},
            {tag: 'titled outside', title: 'Dialog title', method: 'outside'}
        ]
    }

    function attemptDismissal(method, close) {
        if (method === 'close') mouseClick(close)
        else if (method === 'escape') keyClick(Qt.Key_Escape)
        else mouseClick(self, 1, 1)
    }

    function test_dialogDismissible(row) {
        const dialog = createTemporaryObject(dialog_component, self, {title: row.title})
        compare(dialog.dismissible, true)
        dialog.open()
        tryCompare(dialog, 'opened', true)
        const close = findItems(dialog.header, item => item instanceof UiIconButton)[0]
        dialog.dismissible = false
        compare(dialog.closePolicy, Controls.Popup.NoAutoClose)
        verify(!close.visible)
        verify(!close.enabled)
        compare(dialog.header.visible, row.title.length > 0)
        attemptDismissal(row.method, close)
        verify(dialog.opened)
        compare(dialog.rejectedCount, 0)
        dialog.dismissible = true
        verify(close.visible)
        verify(close.enabled)
        attemptDismissal(row.method, close)
        tryCompare(dialog, 'visible', false)
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
