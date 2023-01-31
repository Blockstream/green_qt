import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Layouts
import QtQml.Models

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

AbstractDialog {
    id: self
    icon: {
        if (controller.type === 'amp') return 'qrc:/svg/amp.svg'
        if (controller.network) return UtilJS.iconFor(controller.network)
        return null
    }
    title: qsTrId('id_create_new_wallet')
    closePolicy: Popup.NoAutoClose
    width: 900
    height: 600

    Navigation {
        id: navigation
        Component.onCompleted: location = window.navigation.location
    }

    SignupController {
        id: controller
        network: {
            const network = navigation.param.network || ''
            const server_type = navigation.param.type === 'amp' ? 'green' : (navigation.param.server_type || '')
            return NetworkManager.networkWithServerType(network, server_type)
        }
        type: navigation.param.type || ''
        pin: navigation.param.pin || ''
        mnemonic: (navigation.param.mnemonic || '').split(',')
        active: navigation.param.verify || false
        onFinished: wallet_create_event.track()
    }

    AnalyticsEvent {
        id: wallet_create_event
        name: 'wallet_create'
        active: true
        segmentation: AnalyticsJS.segmentationSession(controller.wallet)
    }

    Connections {
        target: controller.wallet
        function onReadyChanged(ready) {
            if (ready) window.navigation.go(`/${controller.network.key}/${controller.wallet.id}`)
        }
    }

    footer: DialogFooter {
        GButton {
            large: true
            visible: navigation.canPop
            text: qsTrId('id_back')
            onClicked: navigation.pop()
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

    contentItem: StackLayout {
        property Item currentItem: {
            if (stack_layout.currentIndex < 0) return null
            let item = stack_layout.children[stack_layout.currentIndex]
            if (item instanceof Loader) item = item.item
            if (item) item.focus = true
            return item
        }
        id: stack_layout
        currentIndex: {
            let index = -1
            for (let i = 0; i < stack_layout.children.length; ++i) {
                let child = stack_layout.children[i]
                if (!(child instanceof Item)) continue
                if (child.active) index = i
            }
            return index
        }
        SelectNetworkView {
            id: select_network_view
            readonly property bool active: true
            showAMP: true
            view: 'signup'
            AnalyticsView {
                active: select_network_view.visible
                name: 'OnBoardChooseNetwork'
                segmentation: AnalyticsJS.segmentationOnBoard({
                    flow: 'create',
                })
            }
        }

        AnimLoader {
            id: select_server_type_view
            active: (navigation.param.network || false) && (navigation.param.type || false) && !controller.network
            animated: self.opened
            sourceComponent: SelectServerTypeView {
            }
            AnalyticsView {
                active: select_server_type_view.visible
                name: 'OnBoardChooseSecurity'
                segmentation: AnalyticsJS.segmentationOnBoard({
                    flow: 'create',
                    network: navigation.param.network === 'bitcoin' ? 'mainnet' : navigation.param.network,
                })
            }
        }

        AnimLoader {
            active: controller.network && !controller.network.liquid
            animated: self.opened
            sourceComponent: WelcomePage {
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
            active: controller.network && controller.network.liquid && controller.type === 'default'
            animated: self.opened
            sourceComponent: GPane {
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
                        text: qsTrId('id_faster_more_confidential')
                        font.pixelSize: 28
                        font.bold: true
                        wrapMode: Text.WordWrap
                    }
                    Label {
                        Layout.maximumWidth: 500
                        text: qsTrId('id_liquid_is_a_sidechainbased')
                        font.pixelSize: 16
                        wrapMode: Text.WordWrap
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
                            text: qsTrId('id_i_agree_to_the') + ' ' + UtilJS.link('https://blockstream.com/green/terms/', qsTrId('id_terms_of_service'))
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
            active: controller.network && controller.network.key === 'liquid' && controller.type === 'amp'
            animated: self.opened
            sourceComponent: GPane {
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
                        text: qsTrId('id_send_and_receive_liquidbased')
                        font.pixelSize: 28
                        font.bold: true
                        wrapMode: Text.WordWrap
                    }
                    Label {
                        Layout.maximumWidth: 500
                        text: qsTrId('id_well_get_you_set_up_with_an_amp')
                        font.pixelSize: 16
                        wrapMode: Text.WordWrap
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
                            text: qsTrId('id_i_agree_to_the') + ' ' + UtilJS.link('https://blockstream.com/green/terms/', qsTrId('id_terms_of_service'))
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
                id: mnemonic_page
                property list<Action> actions: [
                    Action {
                        text: qsTrId('id_continue')
                        onTriggered: navigation.set({ backup: true, size: mnemonicSize, mnemonic: mnemonic_page.mnemonic.join(',') })
                    }
                ]
                mnemonic: controller.generateMnemonic(mnemonicSize || 12)
            }
        }
        AnimLoader {
            active: navigation.param.backup || false
            animated: self.opened
            sourceComponent: MnemonicQuizPage {
                mnemonic: controller.mnemonic
                onCompleteChanged: if (complete) navigation.set({ quiz: true })
                AnalyticsView {
                    active: true
                    name: 'RecoveryCheck'
                    segmentation: AnalyticsJS.segmentationNetwork(controller.network)
                }
            }
        }
        AnimLoader {
            id: set_pin_view
            active: navigation.param.quiz || false
            animated: self.opened
            sourceComponent: Pane {
                background: null
                contentItem: ColumnLayout {
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
            AnalyticsView {
                active: set_pin_view.visible
                name: 'OnBoardPin'
                segmentation: AnalyticsJS.segmentationOnBoard({
                    flow: 'create',
                    network: navigation.param.network === 'bitcoin' ? 'mainnet' : navigation.param.network,
                    security: navigation.param.server_type === 'electrum' ? 'singlesig' : 'multisig'
                })
            }
        }
        AnimLoader {
            active: navigation.param.pin || false
            animated: self.opened
            sourceComponent: Pane {
                background: null
                contentItem: ColumnLayout {
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
                    text: qsTrId('id_creating_wallet')
                }
                VSpacer {}
            }
        }
    }
}
