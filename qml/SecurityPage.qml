import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    required property Context context
    property bool backupCompleted: !Settings.isEventRegistered({ walletId: self.context.xpubHashId, status: 'pending', type: 'wallet_backup' })
    readonly property JadeDevice jadeDevice: self.context?.device instanceof JadeDevice ? self.context.device : null    
    readonly property bool deviceReady: (self.jadeDevice?.connected && 'BOARD_TYPE' in self.jadeDevice?.versionInfo) ?? false
    objectName: "SecurityPage"
    
    Component.onCompleted: {
        if (self.jadeDevice) {
            firmware_controller.check(self.jadeDevice)
        }
    }
    
    Connections {
        target: self.jadeDevice
        function onConnectedChanged() {
            if (self.jadeDevice?.connected) {
                firmware_controller.check(self.jadeDevice)
            }
        }
    }
    
    JadeFirmwareController {
        id: firmware_controller
    }
    
    Connections {
        target: firmware_controller
        function onIndexChanged() {
            if (firmware_controller.index && Object.keys(firmware_controller.index).length > 0) {
                firmware_check_controller.check()
            }
        }
    }
    
    JadeFirmwareCheckController {
        id: firmware_check_controller
        index: firmware_controller.index
        device: self.jadeDevice
    }
    
    readonly property var firmwares: {
        if (!self.deviceReady) return []
        if (firmware_controller.fetching) return []
        const fws = []
        for (const fw of firmware_check_controller.firmwares) {
            if (fw.config !== self.jadeDevice.versionInfo.JADE_CONFIG.toLowerCase()) continue
            if (!fw.upgrade) continue
            if (!fw.compatible) continue
            if (fw.has_delta) continue
            fws.push(fw)
        }
        return fws
    }
    
    readonly property var latestFirmware: {
        if (!self.deviceReady) return null
        if (firmware_controller.fetching) return null
        for (const firmware of self.firmwares) {
            if (firmware.latest) {
                return firmware
            }
        }
        return null
    }
    
    readonly property bool runningLatest: {
        if (!self.deviceReady) return true
        if (firmware_controller.fetching) return true
        if (self.latestFirmware) {
            return self.jadeDevice && self.jadeDevice.version === self.latestFirmware.version
        }
        if (self.firmwares.length === 0) {
            return true
        }
        return false
    }
    
    readonly property bool firmwareUpdateAvailable: !self.runningLatest && self.latestFirmware !== null
    
    Connections {
        target: Settings
        function onRegisteredEventsCountChanged() {
            self.backupCompleted = !Settings.isEventRegistered({ walletId: self.context.xpubHashId, status: 'pending', type: 'wallet_backup' })
        }
    }

    component InfoCard: Pane {
        required property string iconSource
        required property string title
        required property string description
        required property list<Component> linkButtons
        required property Action rightAction
        property bool iconSide: false
        property bool warningDot: false
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredWidth: 0
        id: card
        padding: 20
        background: Rectangle {
            color: Qt.lighter('#181818', card.hovered ? 1.2 : 1)
            border.color: '#262626'
            border.width: 1
            radius: 5
        }
        contentItem: Item {
            implicitWidth: iconSide ? horizontalLayout.implicitWidth + 20 : verticalLayout.implicitWidth + 20
            implicitHeight: iconSide ? horizontalLayout.implicitHeight + 20 : verticalLayout.implicitHeight + 20

            MouseArea {
                anchors.fill: parent
                anchors.margins: -20
                enabled: card.rightAction.enabled
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                preventStealing: true
                onClicked: card.rightAction.trigger()
            }

            ColumnLayout {
                id: verticalLayout
                spacing: 8
                visible: !iconSide
                Image {
                    source: iconSource
                }
                RowLayout {
                    spacing: 8
                    Label {
                        text: title
                        font.pixelSize: 20
                        font.weight: 600
                        color: '#FFFFFF'
                    }
                    HSpacer {}
                    Item {
                        visible: card.rightAction.enabled
                        Layout.alignment: Qt.AlignTop
                        width: 24; height: 24
                        Image {
                            source: 'qrc:/svg/arrow_right.svg'
                            anchors.centerIn: parent
                            width: 20; height: 20
                        }
                    }
                }

                Label {
                    Layout.topMargin: -6
                    text: description
                    font.pixelSize: 14
                    color: '#A0A0A0'
                    wrapMode: Label.Wrap
                }

                ColumnLayout {
                    spacing: 4
                    Layout.topMargin: 6
                    Repeater {
                        model: linkButtons
                        delegate: Loader {
                            sourceComponent: modelData
                        }
                    }
                }
            }

            RowLayout {
                id: horizontalLayout
                anchors.fill: parent
                spacing: 12
                visible: iconSide

                Image {
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: 4
                    source: iconSource
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignTop
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Label {
                            text: title
                            font.pixelSize: 20
                            font.weight: 600
                            color: '#FFFFFF'
                        }
                        Rectangle {
                            visible: warningDot
                            Layout.alignment: Qt.AlignVCenter
                            width: 12
                            height: 12
                            radius: 6
                            color: '#FF0000'
                        }
                        HSpacer {}
                        Item {
                            visible: card.rightAction.enabled
                            Layout.alignment: Qt.AlignTop
                            width: 24; height: 24
                            Image {
                                source: 'qrc:/svg/arrow_right.svg'
                                anchors.centerIn: parent
                                width: 20; height: 20
                            }
                        }
                    }

                    Label {
                        Layout.fillWidth: true
                        text: description
                        font.pixelSize: 14
                        color: '#A0A0A0'
                        wrapMode: Label.Wrap
                        elide: Text.ElideNone
                    }

                    ColumnLayout {
                        spacing: 8
                        Repeater {
                            model: linkButtons
                            delegate: Loader {
                                sourceComponent: modelData
                            }
                        }
                    }
                }
            }
        }
    }

    id: self
    background: null
    contentItem: VFlickable {
        alignment: Qt.AlignTop
        ColumnLayout {
            spacing: 16
            // Software Wallet Section
            ColumnLayout {
                visible: self.context.wallet.login?.device?.type !== 'jade'
                spacing: 16
                Label {
                    text: 'Your keys, your bitcoin.'
                    font.pixelSize: 20
                    font.weight: 600
                    color: '#FFFFFF'
                }
                Label {
                    textFormat: Text.RichText
                    text: 'Your Software Wallet keeps your bitcoin secured by private keys stored on your computer or mobile device. Only you control them. Protect your wallet and recovery phrase with these key practices:'
                    font.pixelSize: 14
                    color: '#A0A0A0'
                    wrapMode: Label.Wrap
                    Layout.fillWidth: true
                }
                RowLayout {
                    spacing: 24
                    ColumnLayout {
                        spacing: 8
                        Layout.preferredWidth: 1
                        visible: !self.context.watchonly
                        Label {
                            text: "Unlock Method"
                            color: "#A0A0A0"
                            font.pixelSize: 14
                        }
                        InfoCard {
                            iconSource: 'qrc:/svg3/Pin.svg'
                            title: 'PIN'
                            description: 'Secure your wallet with a personal 6-digit PIN. It\'s a quick and convenient way to unlock your wallet without using your hardware device every time.'
                            linkButtons: []
                            iconSide: true
                            rightAction: Action {
                                onTriggered: {
                                    const drawer = change_pin_drawer.createObject(self)
                                    drawer.open()
                                }
                            }
                        }
                    }
                    ColumnLayout {
                        spacing: 8
                        Layout.preferredWidth: 1
                        visible: self.context.wallet.login instanceof PinData
                        Label {
                            text: "Recovery Method"
                            color: "#A0A0A0"
                            font.pixelSize: 14
                        }
                        InfoCard {
                            iconSource: 'qrc:/svg3/Backup.svg'
                            title: 'Manual Backup'
                            description: 'Write down your recovery phrase and store it safely. This is the most secure way to back up your wallet and regain access if your device is lost or reset.'
                            warningDot: !self.backupCompleted
                            linkButtons: [
                                Component {
                                    RowLayout {
                                        visible: !self.backupCompleted
                                        Layout.topMargin: 8
                                        Layout.fillWidth: true
                                        spacing: 8
                                        Image {
                                            source: 'qrc:/svg3/Warning.svg'
                                            Layout.alignment: Qt.AlignTop
                                            Layout.topMargin: 2
                                            width: 16
                                            height: 16
                                        }
                                        Label {
                                            Layout.fillWidth: true
                                            text: 'You haven\'t backed up your wallet yet.'
                                            font.pixelSize: 14
                                            font.weight: 600
                                            color: '#FF6467'
                                            wrapMode: Label.Wrap
                                        }
                                    }
                                }
                            ]
                            iconSide: true
                            rightAction: Action {
                                onTriggered: {
                                    const drawer = backup_drawer.createObject(self)
                                    drawer.open()
                                }
                            }
                        }
                    }
                }
                RowLayout {
                    Layout.topMargin: 8
                    Pane {
                        Layout.fillWidth: true
                        padding: 20
                        background: Rectangle {
                            color: '#181818'
                            border.color: '#262626'
                            border.width: 1
                            radius: 4
                        }
                        contentItem: RowLayout {
                            RowLayout {
                                Layout.preferredWidth: 1
                                spacing: 24
                                Image {
                                    id: icon
                                    source: 'qrc:/svg3/Jade.svg'
                                    fillMode: Image.PreserveAspectFit
                                    Layout.alignment: Qt.AlignVCenter
                                }
                                ColumnLayout {
                                    spacing: 8
                                    Label {
                                        text: 'Upgrade Your Security with Jade.'
                                        font.pixelSize: 20
                                        font.weight: 600
                                        color: '#FFFFFF'
                                        Layout.fillWidth: true
                                        wrapMode: Label.Wrap
                                    }
                                    Label {
                                        text: 'You\'re currently using a software wallet, which is great for everyday spending. For stronger protection, upgrade to a Jade hardware wallet.'
                                        font.pixelSize: 14
                                        color: '#A0A0A0'
                                        wrapMode: Label.Wrap
                                        Layout.fillWidth: true
                                    }
                                    LinkButton {
                                        text: 'Shop Now'
                                        font.pixelSize: 14
                                        onClicked: Qt.openUrlExternally('https://store.blockstream.com/products/jade-plus')
                                    }
                                }
                            }
                            Rectangle {
                                width: 1
                                color: '#262626'
                                Layout.fillHeight: true
                                Layout.leftMargin: 12
                                Layout.rightMargin: 12
                            }
                            ColumnLayout {
                                Layout.preferredWidth: 1
                                spacing: 8
                                Label {
                                    text: 'Jade secures your keys on a physical device designed to:'
                                    font.pixelSize: 14
                                    color: '#A0A0A0'
                                    wrapMode: Label.Wrap
                                    Layout.fillWidth: true 
                                }
                                Label {
                                    text: '\u2022 Safeguard bitcoin for long-term storage'
                                    font.pixelSize: 14
                                    color: '#A0A0A0'
                                    wrapMode: Label.Wrap
                                    Layout.leftMargin: 10
                                }
                                Label {
                                    text: '\u2022 Protect against common attack vectors'
                                    font.pixelSize: 14
                                    color: '#A0A0A0'
                                    wrapMode: Label.Wrap
                                    Layout.leftMargin: 10
                                }
                                Label {
                                    text: '\u2022 Isolate your keys from all other devices'
                                    font.pixelSize: 14
                                    color: '#A0A0A0'
                                    wrapMode: Label.Wrap
                                    Layout.leftMargin: 10
                                }
                            }
                        }
                    }
                }
            }
            // Hardware Wallet Section
            ColumnLayout {
                visible: self.context.wallet.login?.device?.type === 'jade'
                spacing: 16
                Label {
                    text: 'Your keys, your bitcoin.'
                    font.pixelSize: 20
                    font.weight: 600
                    color: '#FFFFFF'
                }
                Label {
                    id: hardware_wallet_label
                    textFormat: Text.RichText
                    text: 'Your <a href="#" style="text-decoration: none; color: #00BCFF">Hardware Wallet</a> keeps your bitcoin safe by securing keys on a dedicated device, never on your computer or phone. Only you control them. Protect your wallet and recovery phrase with these key practices:'
                    font.pixelSize: 14
                    color: '#A0A0A0'
                    wrapMode: Label.Wrap
                    Layout.fillWidth: true
                    onLinkActivated: {
                        if (self.jadeDevice) {
                            const drawer = jade_details_drawer.createObject(self)
                            drawer.open()
                        }
                    }
                    HoverHandler {
                        enabled: hardware_wallet_label.hoveredLink
                        cursorShape: Qt.PointingHandCursor
                    }
                }
                RowLayout {
                    spacing: 24
                    ColumnLayout {
                        Layout.preferredWidth: 1
                        spacing: 8
                        visible: self.context.wallet.login?.device?.board === 'JADE_V2'
                        Label {
                            text: "Jade’s Authenticity"
                            color: "#A0A0A0"
                            font.pixelSize: 14
                        }
                        InfoCard {
                            iconSource: 'qrc:/svg3/Stamp.svg'
                            title: 'Genuine Check'
                            description: 'Verify that your device is authentic and safe to use prior to managing funds.'
                            linkButtons: []
                            iconSide: true
                            rightAction: Action {
                                onTriggered: {
                                    if (self.jadeDevice) {
                                        const dialog = genuine_check_dialog.createObject(self, {
                                            device: self.jadeDevice,
                                            autoCheck: true
                                        })
                                        dialog.open()
                                    }
                                }
                            }
                        }
                    }
                    ColumnLayout {
                        spacing: 8
                        Layout.preferredWidth: 1
                        Label {
                            text: 'Firmware Upgrade'
                            color: "#A0A0A0"
                            font.pixelSize: 14
                        }
                        InfoCard {
                            iconSource: 'qrc:/svg3/Graphic-card.svg'
                            title: 'Firmware Upgrade'
                            description: 'Update your Jade Firmware for the latest features, improvements, and protection for your assets.'
                            linkButtons: [
                                Component {
                                    RowLayout {
                                        Layout.topMargin: 8
                                        Layout.fillWidth: true
                                        spacing: 8
                                        Image {
                                            visible: self.firmwareUpdateAvailable
                                            source: 'qrc:/svg3/Warning-yellow.svg'
                                            Layout.alignment: Qt.AlignTop
                                            Layout.topMargin: 2
                                            width: 16
                                            height: 16
                                        }
                                        Label {
                                            Layout.fillWidth: true
                                            text: self.firmwareUpdateAvailable ? 'Update to ' + self.latestFirmware.version : 'Firmware up to date: version ' + (self.jadeDevice?.version ?? '')
                                            font.pixelSize: 14
                                            font.weight: 600
                                            color: self.firmwareUpdateAvailable ? '#FDC700' : '#A0A0A0'
                                            wrapMode: Label.Wrap
                                        }
                                    }   
                                }
                            ]
                            iconSide: true
                            rightAction: Action {
                                onTriggered: {
                                    const dialog = update_firmware_dialog.createObject(self, {
                                        device: self.jadeDevice
                                    })
                                    dialog.open()
                                }
                            }
                        }
                    }
                }
            }
            Label {
                text: qsTrId('id_learn_more')
                font.pixelSize: 20
                font.weight: 600
                color: '#FFFFFF'
                Layout.topMargin: 12
                Layout.bottomMargin: -4
            }
            RowLayout {
                spacing: 24
                InfoCard {
                    iconSource: 'qrc:/svg3/questions.svg'
                    title: 'FAQs'
                    description: 'Quick answers to common questions'
                    hoverEnabled: false
                    rightAction: Action {
                        enabled: false
                    }
                    linkButtons: [
                        Component {
                            LinkButton {
                                text: 'What is a recovery phrase?'
                                font.pixelSize: 14
                                onClicked: Qt.openUrlExternally('https://help.blockstream.com/hc/en-us/articles/900001392563-What-is-a-recovery-phrase')
                            }
                        },
                        Component {
                            LinkButton {
                                text: 'How does the Blockstream app generate my recovery phrase?'
                                font.pixelSize: 14
                                onClicked: Qt.openUrlExternally('https://help.blockstream.com/hc/en-us/articles/47242018755993-How-does-the-Blockstream-app-generate-my-recovery-phrase')
                            }
                        },
                        Component {
                            LinkButton {
                                text: 'How is my software wallet security different than Jade\'s?'
                                font.pixelSize: 14
                                onClicked: Qt.openUrlExternally('https://help.blockstream.com/hc/en-us/articles/52243836841369-How-is-my-software-wallet-security-different-than-Jade-s')
                            }
                        }
                    ]
                }
                HSpacer {
                }
            }
            VSpacer {
                Layout.minimumHeight: 40
            }
        }
    }

    Component {
        id: change_pin_drawer
        ChangePinDrawer {
            context: self.context
        }
    }

    Component {
        id: backup_drawer
        BackupDrawer {
            context: self.context
        }
    }

    Component {
        id: genuine_check_dialog
        JadeGenuineCheckDialog {
            id: dialog
            onGenuine: {
                if (Settings.rememberDevices && dialog.device) {
                    const efusemac = dialog.device.versionInfo.EFUSEMAC
                    Settings.registerEvent({ efusemac, result: 'genuine', type: 'jade_genuine_check' })
                }
                dialog.close()
            }
            onDiy: {
                if (Settings.rememberDevices && dialog.device) {
                    const efusemac = dialog.device.versionInfo.EFUSEMAC
                    Settings.registerEvent({ efusemac, result: 'diy', type: 'jade_genuine_check' })
                }
                dialog.close()
            }
            onSkip: {
                if (Settings.rememberDevices && dialog.device) {
                    const efusemac = dialog.device.versionInfo.EFUSEMAC
                    Settings.registerEvent({ efusemac, result: 'skip', type: 'jade_genuine_check' })
                }
                dialog.close()
            }
            onAbort: {
                dialog.close()
            }
        }
    }

    Component {
        id: update_firmware_dialog
        JadeUpdateDialog2 {
            context: self.context
            device: self.jadeDevice
        }
    }

    Component {
        id: jade_details_drawer
        JadeDetailsDrawer {
            device: self.jadeDevice
        }
    }
}
