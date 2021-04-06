import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.15
import QtQml 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQml.Models 2.0

AbstractDialog {
    id: self
    icon: controller.type === 'amp' ? 'qrc:/svg/amp.svg' : controller.network ? icons[controller.network.id] : null
    title: qsTrId('id_create_new_wallet')
    closePolicy: Popup.NoAutoClose
    width: 1000
    height: 500

    SignupController {
        id: controller
        network: NetworkManager.network(navigation.param.network || '')
        type: navigation.param.type || ''
        pin: navigation.param.pin || ''
        active: navigation.param.verify || false
    }

    Connections {
        target: controller.wallet
        function onReadyChanged(ready) {
            if (ready) navigation.go(`/${controller.network.id}/${controller.wallet.id}`)
        }
    }

    Connections {
        target: controller.wallet ? controller.wallet.session : null
        function onActivityCreated(activity) {
            if (activity instanceof SessionTorCircuitActivity) {
                session_tor_cirtcuit_view.createObject(activities_row, { activity })
            } else if (activity instanceof SessionConnectActivity) {
                session_connect_view.createObject(activities_row, { activity })
            }
        }
    }

    footer: DialogFooter {
        GButton {
            action: stack_layout.currentItem ? stack_layout.currentItem.backAction || null : null
            large: true
            visible: action
        }
        Pane {
            Layout.minimumHeight: 48
            background: null
            padding: 0
            contentItem: RowLayout {
                id: activities_row
            }
        }
        HSpacer {}
        Repeater {
            model: stack_layout.currentItem ? stack_layout.currentItem.actions || null : null
            GButton {
                action: modelData
                large: true
            }
        }
    }

    property bool closing: false
    onAboutToHide: closing = true
    contentItem: StackLayout {
        property Item currentItem: {
            if (stack_layout.currentIndex < 0) return null
            let item = stack_layout.children[stack_layout.currentIndex]
            if (item instanceof Loader) item = item.item
            if (item) item.focus = true
            return item
        }
        id: stack_layout
        Binding on currentIndex {
            when: !self.closing
            restoreMode: Binding.RestoreNone
            value: {
                let index = -1
                for (let i = 0; i < stack_layout.children.length; ++i) {
                    let child = stack_layout.children[i]
                    if (!(child instanceof Item)) continue
                    if (child.active) index = i
                }
                return index
            }
        }
        SelectNetworkView {
            readonly property bool active: true
            showAMP: true
            view: 'signup'
        }

        AnimLoader {
            active: controller.network && controller.network.id !== 'liquid'
            animated: self.opened
            sourceComponent: WelcomePage {
                readonly property Action backAction: Action {
                    enabled: navigation.path === '/signup'
                    text: qsTrId('id_back')
                    onTriggered: navigation.set({ network: undefined, type: undefined })
                }
                readonly property list<Action> actions: [
                    Action {
                        text: qsTrId('id_continue')
                        enabled: agreeWithTermsOfService
                        onTriggered: navigation.set({ tos: true })
                    }
                ]
            }
        }
        AnimLoader {
            active: controller.network && controller.network.id === 'liquid' && controller.type === 'default'
            animated: self.opened
            sourceComponent: Pane {
                readonly property Action backAction: Action {
                    text: qsTrId('id_back')
                    onTriggered: navigation.set({ network: undefined, type: undefined })
                }
                readonly property list<Action> actions: [
                    Action {
                        text: qsTrId('id_continue')
                        enabled: checkbox.checked
                        onTriggered: navigation.set({ tos: true })
                    }
                ]
                background: Item {
                    Image {
                        OpacityAnimator on opacity {
                            from: 0
                            to: 0.5
                            duration: 5000
                            easing.type: Easing.OutCirc
                        }
                        ScaleAnimator on scale {
                            from: 1.1
                            to: 1
                            duration: 10000
                            easing.type: Easing.OutCirc
                        }
                        source: 'qrc:/png/liquid_background.png'
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        width: parent.width * 0.8
                        fillMode: Image.PreserveAspectFit
                    }
                }
                contentItem: ColumnLayout {
                    spacing: 32
                    VSpacer {
                    }
                    Label {
                        Layout.maximumWidth: 500
                        text: qsTrId('Faster, more confidential Bitcoin transactions')
                        font.pixelSize: 28
                        font.bold: true
                        wrapMode: Label.WordWrap
                    }
                    Label {
                        Layout.maximumWidth: 500
                        text: qsTrId('Liquid is a sidechain-based settlement network for traders and exchanges, enabling faster, more confidential Bitcoin transactions and the issuance of digital assets.')
                        font.pixelSize: 16
                        wrapMode: Label.WordWrap
                    }
                    RowLayout {
                        Layout.maximumWidth: 500
                        Layout.fillWidth: false
                        Layout.fillHeight: false
                        CheckBox {
                            id: checkbox
                            focus: true
                        }
                        Label {
                            textFormat: Text.RichText
                            text: qsTrId('id_i_agree_to_the') + ' ' + link('https://blockstream.com/green/terms/', qsTrId('id_terms_of_service'))
                            onLinkActivated: Qt.openUrlExternally(link)
                            background: MouseArea {
                                acceptedButtons: Qt.NoButton
                                cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                            }
                        }
                    }
                    VSpacer {
                    }
                }
            }
        }
        AnimLoader {
            active: controller.network && controller.network.id === 'liquid' && controller.type === 'amp'
            animated: self.opened
            sourceComponent: Pane {
                readonly property Action backAction: Action {
                    text: qsTrId('id_back')
                    onTriggered: navigation.set({ network: undefined, type: undefined })
                }
                readonly property list<Action> actions: [
                    Action {
                        text: qsTrId('id_continue')
                        enabled: checkbox.checked
                        onTriggered: navigation.set({ tos: true })
                    }
                ]
                background: Item {
                    Image {
                        OpacityAnimator on opacity {
                            from: 0
                            to: 0.5
                            duration: 5000
                            easing.type: Easing.OutCirc
                        }
                        ScaleAnimator on scale {
                            from: 1.1
                            to: 1
                            duration: 10000
                            easing.type: Easing.OutCirc
                        }

                        source: 'qrc:/png/amp_background.png'
                        anchors.centerIn: parent
                        width: parent.width
                        fillMode: Image.PreserveAspectFit
                    }
                }
                contentItem: ColumnLayout {
                    spacing: 32
                    VSpacer {
                    }
                    Label {
                        Layout.maximumWidth: 500
                        text: qsTrId(`Send and receive Liquid-based Managed Assets`)
                        font.pixelSize: 28
                        font.bold: true
                        wrapMode: Label.WordWrap
                    }
                    Label {
                        Layout.maximumWidth: 500
                        text: qsTrId(`We'll get you set up with an AMP wallet in no time. Note that you can alternatively create AMP accounts in any existing Liquid wallet.`)
                        font.pixelSize: 16
                        wrapMode: Label.WordWrap
                    }
                    RowLayout {
                        Layout.maximumWidth: 500
                        Layout.fillWidth: false
                        Layout.fillHeight: false
                        CheckBox {
                            id: checkbox
                            focus: true
                        }
                        Label {
                            textFormat: Text.RichText
                            text: qsTrId('id_i_agree_to_the') + ' ' + link('https://blockstream.com/green/terms/', qsTrId('id_terms_of_service'))
                            onLinkActivated: Qt.openUrlExternally(link)
                            background: MouseArea {
                                acceptedButtons: Qt.NoButton
                                cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                            }
                        }
                    }
                    VSpacer {
                    }
                }
            }
        }
        AnimLoader {
            active: navigation.param.tos || false
            animated: self.opened
            sourceComponent: MnemonicPage {
                readonly property Action backAction: Action {
                    text: qsTrId('id_back')
                    onTriggered: navigation.set({ tos: undefined })
                }
                property list<Action> actions: [
                    Action {
                        text: qsTrId('id_continue')
                        onTriggered: navigation.set({ backup: true })
                    }
                ]
                mnemonic: controller.mnemonic
            }
        }
//        AnimLoader {
//            active: navigation.param.backup || false
//            sourceComponent: MnemonicQuizView {
//                readonly property Action backAction: Action {
//                    text: qsTrId('id_back')
//                    onTriggered: navigation.set({ backup: undefined })
//                }
//                mnemonic: controller.mnemonic
//                onCompletedChanged: if (completed) navigation.set({ quiz: true })
//                onFailedChanged: if (failed) navigation.set({ backup: undefined })
//            }
//        }
        AnimLoader {
            active: navigation.param.backup || false
            animated: self.opened
            sourceComponent: MnemonicQuizPage {
                readonly property Action backAction: Action {
                    text: qsTrId('id_back')
                    onTriggered: navigation.set({ backup: undefined })
                }
                mnemonic: controller.mnemonic
                onCompleteChanged: if (complete) navigation.set({ quiz: true })
            }
        }
        AnimLoader {
            active: navigation.param.quiz || false
            animated: self.opened
            sourceComponent: ColumnLayout {
                readonly property Action backAction: Action {
                    text: qsTrId('id_back')
                    onTriggered: navigation.set({ backup: undefined, quiz: undefined })
                }
                spacing: 16
                VSpacer {
                }
                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTrId('id_create_a_pin_to_access_your')
                    font.pixelSize: 20
                }
                PinView {
                    Layout.alignment: Qt.AlignHCenter
                    id: pin_view
                    focus: true
                    onPinChanged: {
                        if (!pin.valid) return
                        navigation.set({ pin: pin.value })
                        Qt.callLater(pin_view.clear)
                    }
                }
                VSpacer {
                }
            }
        }
        AnimLoader {
            active: navigation.param.pin || false
            animated: self.opened
            sourceComponent: ColumnLayout {
                spacing: 16
                VSpacer {
                }
                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTrId('id_verify_your_pin')
                    font.pixelSize: 20
                }
                PinView {
                    Layout.alignment: Qt.AlignHCenter
                    id: verify_pin_view
                    focus: true
                    onPinChanged: {
                        if (!pin.valid) return;
                        if (navigation.param.pin === pin.value) {
                            navigation.set({ verify: true })
                        } else {
                            navigation.set({ pin: undefined })
                        }
                    }
                }
                VSpacer {
                }
            }
        }
        AnimLoader {
            active: navigation.param.verify || false
            animated: self.opened
            sourceComponent: ColumnLayout {
                spacing: 16
                VSpacer {}
                BusyIndicator {
                    Layout.alignment: Qt.AlignCenter
                }
                Label {
                    Layout.alignment: Qt.AlignCenter
                    text: {
                        const count = controller.wallet ? controller.wallet.activities.length : 0
                        if (count > 0) {
                            const activity = controller.wallet.activities[count - 1]
                            if (activity instanceof WalletRefreshAssets) {
                                return qsTrId('id_loading_assets')
                            }
                        }
                        return qsTrId('id_creating_wallet')
                    }
                }
                VSpacer {}
            }
        }
    }
}
