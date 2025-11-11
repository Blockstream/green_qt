import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    required property Context context
    signal closed
    signal backupCompleted
    id: self
    background: null
    contentItem: GStackView {
        id: stack_view
        initialItem: backup_warnings_page
    }

    Component {
        id: backup_warnings_page
        StackViewPage {
            title: qsTrId('id_before_you_backup')
            id: backup_warnings_page_instance
            readonly property var backupPage: {
                let sv = backup_warnings_page_instance.StackView.view
                return sv ? sv.parent : null
            }
            leftItem: BackButton {
                onClicked: {
                    if (backup_warnings_page_instance.backupPage) {
                        backup_warnings_page_instance.backupPage.closed()
                    }
                }
            }
            padding: 60
            contentItem: VFlickable {
                alignment: Qt.AlignTop
                ColumnLayout {
                    spacing: 20
                    Layout.alignment: Qt.AlignHCenter
                    Layout.maximumWidth: 325
                    Pane {
                        Layout.alignment: Qt.AlignCenter
                        Layout.fillWidth: true
                        background: null
                        contentItem: ColumnLayout {
                            spacing: 0
                            InfoCard {
                                icon: 'qrc:/svg2/house.svg'
                                title: qsTrId('id_safe_environment')
                                description: qsTrId('id_make_sure_you_are_alone_and_no')
                            }
                            InfoCard {
                                icon: 'qrc:/svg2/warning.svg'
                                title: qsTrId('id_sensitive_information')
                                description: qsTrId('id_whomever_can_access_your')
                            }
                            InfoCard {
                                icon: 'qrc:/svg2/shield_check.svg'
                                title: qsTrId('id_safely_stored')
                                description: qsTrId('id_if_you_forget_it_or_lose_it')
                            }
                        }
                    }
                    PrimaryButton {
                        Layout.alignment: Qt.AlignCenter
                        Layout.minimumWidth: 325
                        text: qsTrId('id_show_recovery_phrase')
                        onClicked: stack_view.push(backup_mnemonic_page)
                    }
                    PrintButton {
                        Layout.alignment: Qt.AlignCenter
                        text: qsTrId('id_print_backup_template')
                    }
                    Item {
                        Layout.fillHeight: true
                        Layout.minimumHeight: 40
                    }
                }
            }
        }
    }

    Component {
        id: backup_mnemonic_page
        StackViewPage {
            title: qsTrId('id_write_down_your_recovery_phrase')
            rightItem: PrintButton {
                text: qsTrId('id_print_backup_template')
            }
            readonly property var backupPage: {
                let sv = page.StackView.view
                return sv ? sv.parent : null
            }
            property alias page: backup_mnemonic_page_instance
            id: backup_mnemonic_page_instance
            padding: 60
            contentItem: VFlickable {
                alignment: Qt.AlignTop
                ColumnLayout {
                    spacing: 20
                    Layout.alignment: Qt.AlignHCenter
                    Label {
                        Layout.fillWidth: true
                        Layout.topMargin: 20
                        horizontalAlignment: Label.AlignHCenter
                        font.pixelSize: 14
                        font.weight: 600
                        opacity: 0.4
                        text: qsTrId('id_store_it_somewhere_safe')
                        wrapMode: Label.Wrap
                    }
                    Pane {
                        Layout.alignment: Qt.AlignCenter
                        Layout.topMargin: 20
                        visible: backup_mnemonic_page_instance.backupPage && backup_mnemonic_page_instance.backupPage.context.mnemonic && backup_mnemonic_page_instance.backupPage.context.mnemonic.length > 0
                        background: null
                        contentItem: MnemonicView {
                            id: mnemonic_view
                            columns: backup_mnemonic_page_instance.backupPage.context.mnemonic.length > 12 ? 4 : 2
                            mnemonic: backup_mnemonic_page_instance.backupPage.context.mnemonic
                        }
                    }
                    PrimaryButton {
                        Layout.alignment: Qt.AlignCenter
                        Layout.minimumWidth: 250
                        Layout.topMargin: 20
                        text: qsTrId('id_next')
                        onClicked: stack_view.push(backup_check_page)
                    }
                    Image {
                        Layout.topMargin: 20
                        Layout.alignment: Qt.AlignCenter
                        source: 'qrc:/svg2/house.svg'
                    }
                    Label {
                        Layout.alignment: Qt.AlignCenter
                        font.pixelSize: 12
                        font.weight: 600
                        text: qsTrId('id_make_sure_to_be_in_a_private')
                    }
                    Item {
                        Layout.fillHeight: true
                        Layout.minimumHeight: 40
                    }
                }
            }
        }
    }

    Component {
        id: backup_check_page
        StackViewPage {
            title: qsTrId('id_recovery_phrase_check')
            id: backup_check_page_instance
            
            readonly property var backupPage: {
                let sv = backup_check_page_instance.StackView.view
                return sv ? sv.parent : null
            }
            
            readonly property var context: backupPage ? backupPage.context : null
            
            readonly property bool completed: {
                if (repeater.count === 0) return false
                for (let i = 0; i < repeater.count; i++) {
                    if (!repeater.itemAt(i).match) {
                        return false
                    }
                }
                return true
            }

            onCompletedChanged: {
                if (backup_check_page_instance.completed) {
                    Settings.registerEvent({ walletId: backup_check_page_instance.context.xpubHashId, result: 'completed', type: 'wallet_backup' })
                    const sv = backup_check_page_instance.StackView.view
                    if (sv) {
                        sv.push(backup_complete_page)
                    }
                }
            }

            StackView.onActivating: {
                if (!backup_check_page_instance.context || !backup_check_page_instance.context.mnemonic) return
                const count = 4
                const size = backup_check_page_instance.context.mnemonic.length
                const indexes = [...Array(size).keys()]
                const result = []
                while (result.length < count) {
                    const remove = indexes.length * Math.random()
                    const [index] = indexes.splice(remove, 1)
                    result.push(index)
                }
                repeater.model = result.sort((a, b) => a - b)
            }

            padding: 60
            contentItem: VFlickable {
                alignment: Qt.AlignTop
                ColumnLayout {
                    spacing: 20
                    Layout.alignment: Qt.AlignHCenter
                    Layout.maximumWidth: 400
                    Label {
                        Layout.alignment: Qt.AlignCenter
                        Layout.bottomMargin: 80
                        font.pixelSize: 14
                        font.weight: 600
                        opacity: 0.4
                        text: qsTrId('id_make_sure_you_got_everything')
                    }
                    Repeater {
                        id: repeater
                        delegate: Collapsible {
                            id: checker
                            readonly property int word: modelData
                            readonly property bool match: backup_check_page_instance.context && backup_check_page_instance.context.mnemonic && backup_check_page_instance.context.mnemonic[checker.word] === field.text
                            Layout.alignment: Qt.AlignCenter
                            Layout.fillWidth: true
                            Layout.topMargin: 10
                            collapsed: index > 0 && !repeater.itemAt(index - 1).match
                            contentHeight: field.implicitHeight
                            contentWidth: field.implicitWidth
                            Rectangle {
                                border.width: 2
                                border.color: '#00BCFF'
                                color: 'transparent'
                                radius: 12
                                anchors.fill: field
                                anchors.margins: -4
                                z: -1
                                visible: {
                                    if (checker.collapsed) return false
                                    if (checker.animating) return false
                                    if (field.activeFocus) {
                                        switch (field.focusReason) {
                                        case Qt.TabFocusReason:
                                        case Qt.BacktabFocusReason:
                                        case Qt.ShortcutFocusReason:
                                            return true
                                        }
                                    }
                                    return false
                                }
                            }
                            TextField {
                                id: field
                                width: parent.width
                                enabled: !checker.match
                                padding: 15
                                topPadding: 15
                                bottomPadding: 15
                                bottomInset: 0
                                leftPadding: 50
                                rightPadding: 40
                                font.pixelSize: 14
                                font.weight: 400
                                focus: !parent.collapsed && !parent.match
                                background: Rectangle {
                                    radius: 5
                                    color: '#222226'
                                    Label {
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        anchors.margins: 15
                                        font.pixelSize: 14
                                        font.weight: 700
                                        text: checker.word + 1
                                    }
                                    Image {
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.right: parent.right
                                        anchors.margins: 15
                                        source: 'qrc:/svg2/check-green.svg'
                                        opacity: checker.match ? 1 : 0
                                        Behavior on opacity {
                                            SmoothedAnimation {
                                                velocity: 4
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Image {
                        Layout.topMargin: 20
                        Layout.alignment: Qt.AlignCenter
                        source: 'qrc:/svg2/house.svg'
                    }
                    Label {
                        Layout.alignment: Qt.AlignCenter
                        font.pixelSize: 12
                        font.weight: 600
                        text: qsTrId('id_make_sure_to_be_in_a_private')
                    }
                    Item {
                        Layout.fillHeight: true
                        Layout.minimumHeight: 40
                    }
                }
            }
        }
    }

    Component {
        id: backup_complete_page
        StackViewPage {
            title: qsTrId('id_completed')
            leftItem: Item {}
            padding: 60
            contentItem: ColumnLayout {
                spacing: 20
                VSpacer {}
                Label {
                    Layout.alignment: Qt.AlignCenter
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    horizontalAlignment: Label.AlignHCenter
                    font.pixelSize: 22
                    font.weight: 600
                    text: qsTrId('id_completed')
                    wrapMode: Label.Wrap
                }
                Label {
                    Layout.alignment: Qt.AlignCenter
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    Layout.maximumWidth: 400
                    horizontalAlignment: Label.AlignHCenter
                    font.pixelSize: 14
                    opacity: 0.6
                    text: 'You have successfully verified your recovery phrase backup.'
                    wrapMode: Label.Wrap
                }
                VSpacer {}
                PrimaryButton {
                    Layout.alignment: Qt.AlignCenter
                    Layout.minimumWidth: 250
                    text: qsTrId('id_done')
                    onClicked: {
                        self.backupCompleted()
                        self.closed()
                    }
                }
                VSpacer {}
            }
        }
    }
}

