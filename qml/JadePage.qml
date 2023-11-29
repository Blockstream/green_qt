import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

StackViewPage {
    signal loginFinished(Context context)
    signal skip(Device device)
    required property JadeDevice device
    property bool debug_jade: false
    leftItem: BackButton {
        onClicked: {
            if (stack_view.currentItem.StackView.index > 0) {
                stack_view.pop()
            } else {
                self.StackView.view.pop()
            }
        }
        visible: stack_view.currentItem.StackView.index > 0 || self.StackView.index > 0
        enabled: stack_view.currentItem.StackView.status === StackView.Active && self.StackView.status === StackView.Active
    }
    JadeUpdateController {
        id: update_controller
        index: firmware_controller.index
        device: self.device
//        onActivityCreated: (activity) => {
//            if (activity instanceof JadeUnlockActivity) {
//                activity.failed.connect(() => { stack_view.pop() })
//                activity.finished.connect(() => { stack_view.pop() })
//                stack_view.push(jade_unlock_view, { activity })
//            } else if (activity instanceof JadeUpdateActivity) {
//                activity.failed.connect(() => { stack_view.pop() })
//                stack_view.push(jade_update_view, { activity })
//            }
//        }
//        onFirmwareAvailableChanged: {
//            // we don't want to prompt firmware update
//            // in when Jade setup is in progress
//            if (self.device.state === JadeDevice.StateUnsaved) return

//            if (firmwareAvailable) {
//                self.quickUpdate()
//            }
//        }
//        onUpdateStarted: {
//            Analytics.recordEvent('ota_start', AnalyticsJS.segmentationFirmwareUpdate(self.device, controller.firmwareSelected))
//        }
//        onUpdateCompleted: {
//            Analytics.recordEvent('ota_complete', AnalyticsJS.segmentationFirmwareUpdate(self.device, controller.firmwareSelected))
//        }
    }
    id: self
    padding: 60
    title: self.device.name
    rightItem: LinkButton {
        Layout.alignment: Qt.AlignCenter
        Layout.topMargin: 20
        text: qsTrId('id_setup_guide')
        visible: self.device.state === JadeDevice.StateUninitialized
        onClicked: Qt.openUrlExternally('https://help.blockstream.com/hc/en-us/articles/19629901272345-Set-up-Jade')
    }
    /*
    footer: Pane {
        background: null
        padding: self.padding
        contentItem: ColumnLayout {
            BusyIndicator {
                Layout.alignment: Qt.AlignCenter
                running: firmware_controller.fetching
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                // text: JSON.stringify(update_controller.firmwareAvailable, null, '  ')
                font.pixelSize: 12
                font.weight: 600
                text: !!update_controller.firmwareAvailable ? `Firmware version ${update_controller.firmwareAvailable.version} is available for your Blockstream Jade.` : ''
            }
        }
    }
    */

//            CheckBox {
//                id: show_all_checkbox
//                // visible: self.debug_jade
//                text: qsTrId('id_show_all')
//            }
//            HSpacer {
//            }
//    //        Label {
//    //            text: qsTrId('id_fetching_new_firmware')
//    //            visible: controller.fetching
//    //        }
//    //        GButton {
//    //            large: true
//    //            text: qsTrId('id_next')
//    //            enabled: button_group.checkedButton && !controller.updating
//    //            onClicked: controller.update(button_group.checkedButton.firmware)
//    //        }
//        }
//    }
    readonly property var firmwares: {
        const fws = []
        for (const fw of update_controller.firmwares) {
            if (fw.config !== self.device.versionInfo.JADE_CONFIG.toLowerCase()) continue
            if (!fw.upgrade) continue
            if (!fw.compatible) continue
            if (fw.has_delta) continue
            fws.push(fw)
            break
        }
        return fws
    }

    function pushView() {
        if (!self.device.connected) {
            // TODO
            return
        }

        if (self.device.updateRequired || self.firmwares.length > 0) {
            stack_view.push(basic_update_view)
            return
        }

        skipFirmwareUpdate()
    }

    function skipFirmwareUpdate() {
        switch (self.device.state) {
        case JadeDevice.StateLocked:
        case JadeDevice.StateReady:
            stack_view.push(intialized_view)
            break
        case JadeDevice.StateUninitialized:
        case JadeDevice.StateUnsaved:
            stack_view.push(unintialized_view)
            break
        }
    }

    function firmwareVersionAndType(version, config) {
        return `${version} (${config.toLowerCase() === 'noradio' ? qsTrId('id_noradio_firmware') : qsTrId('id_radio_firmware') })`
    }

    Component.onCompleted: pushView()

    contentItem: GStackView {
        id: stack_view
    }

    Component {
        id: basic_update_view
        Page {
            padding: 0
            background: Item {
                BusyIndicator {
                    anchors.centerIn: parent
                    running: firmware_controller.fetching
                }
            }
            footer: Pane {
                background: null
                padding: 60
                contentItem: RowLayout {
                    LinkButton {
                        Layout.alignment: Qt.AlignBottom
                        id: left_item
                        opacity: center_item.opacity
                        text: qsTrId('id_more_options')
                        enabled: left_item.opacity === 1
                        onClicked: stack_view.push(advanced_update_view)
                    }
                    Item {
                        Layout.preferredWidth: Math.max(UtilJS.effectiveWidth(right_item) - UtilJS.effectiveWidth(left_item), 0)
                    }
                    HSpacer {
                    }
                    ColumnLayout {
                        Layout.fillWidth: false
                        visible: self.device.updateRequired
                        Image {
                            Layout.alignment: Qt.AlignCenter
                            source: 'qrc:/svg2/warning.svg'
                        }
                        Label {
                            Layout.alignment: Qt.AlignCenter
                            font.pixelSize: 12
                            font.weight: 600
                            text: qsTrId('id_new_jade_firmware_required')
                        }
                    }
                    HSpacer {
                    }
                    Item {
                        Layout.preferredWidth: Math.max(UtilJS.effectiveWidth(left_item) - UtilJS.effectiveWidth(right_item), 0)
                    }
                    LinkButton {
                        Layout.alignment: Qt.AlignBottom
                        id: right_item
                        text: qsTrId('id_skip')
                        visible: !self.device.updateRequired
                        onClicked: skipFirmwareUpdate()
                    }
                }
            }
            contentItem: ColumnLayout {
                id: center_item
                opacity: firmware_controller.fetching ? 0 : 1
                Behavior on opacity {
                    SmoothedAnimation {
                        velocity: 3
                    }
                }
                VSpacer {
                }
                Image {
                    Layout.alignment: Qt.AlignCenter
                    source: 'qrc:/png/onboard_jade_1.png'
                }
                Label {
                    Layout.alignment: Qt.AlignCenter
                    font.pixelSize: 26
                    font.weight: 600
                    text: qsTrId('id_firmware_update')
                    wrapMode: Label.WordWrap
                }
                Label {
                    Layout.topMargin: 10
                    Layout.alignment: Qt.AlignCenter
                    font.pixelSize: 14
                    font.weight: 400
                    text: qsTr('Keep your Jade secure, upgrade now to the <b>%1</b> firmware version!').arg(self.firmwares[0].version)
                    textFormat: Label.StyledText
                }
                PrimaryButton {
                    Layout.alignment: Qt.AlignCenter
                    Layout.minimumWidth: 325
                    Layout.topMargin: 20
                    text: qsTrId('id_continue')
                    onClicked: stack_view.push(confirm_update_view, { firmware: self.firmwares[0] })
                }
                VSpacer {
                }
            }
        }
    }

    Component {
        id: advanced_update_view
        Page {
            padding: 0
            background: Item {
                BusyIndicator {
                    anchors.centerIn: parent
                    running: firmware_controller.fetching
                }
            }
            footer: Pane {
                background: null
                padding: 60
                topPadding: 20
                contentItem: RowLayout {
                    CheckBox {
                        Layout.alignment: Qt.AlignBottom
                        id: left_item
                        text: qsTrId('id_show_all')
                        visible: false
                    }
                    Item {
                        Layout.preferredWidth: Math.max(UtilJS.effectiveWidth(right_item) - UtilJS.effectiveWidth(left_item), 0)
                    }
                    HSpacer {
                    }
                    ColumnLayout {
                        Layout.fillWidth: false
                        visible: self.device.updateRequired
                        Image {
                            Layout.alignment: Qt.AlignCenter
                            source: 'qrc:/svg2/warning.svg'
                        }
                        Label {
                            Layout.alignment: Qt.AlignCenter
                            font.pixelSize: 12
                            font.weight: 600
                            text: qsTrId('id_new_jade_firmware_required')
                        }
                    }
                    HSpacer {
                    }
                    Item {
                        Layout.preferredWidth: Math.max(UtilJS.effectiveWidth(left_item) - UtilJS.effectiveWidth(right_item), 0)
                    }
                    LinkButton {
                        Layout.alignment: Qt.AlignBottom
                        id: right_item
                        text: qsTrId('id_skip')
                        visible: !self.device.updateRequired
                        onClicked: skipFirmwareUpdate()
                    }
                }
            }
            contentItem: ColumnLayout {
                opacity: firmware_controller.fetching ? 0 : 1
                Behavior on opacity {
                    SmoothedAnimation {
                        velocity: 3
                    }
                }
                Label {
                    Layout.alignment: Qt.AlignCenter
                    font.pixelSize: 26
                    font.weight: 600
                    text: qsTrId('id_firmware_update')
                    wrapMode: Label.WordWrap
                }
                JadeFirmwareConfigSelector {
                    Layout.topMargin: 20
                    id: config_selector
                    config: self.device.versionInfo.JADE_CONFIG.toLowerCase()
                    onConfigClicked: (config) => config_selector.config = config
                }
                Label {
                    Layout.alignment: Qt.AlignCenter
                    Layout.topMargin: 10
                    Layout.fillWidth: true
                    Layout.minimumHeight: 80
                    Layout.maximumWidth: 300
                    Layout.preferredWidth: 0
                    font.pixelSize: 12
                    font.weight: 500
                    horizontalAlignment: Label.AlignHCenter
                    opacity: 0.4
                    text: {
                        if (config_selector.config === 'ble') {
                            return qsTrId('id_choose_this_version_to_connect')
                        }
                        if (config_selector.config === 'noradio') {
                            return qsTrId('id_choose_this_version_to_disable')
                        }
                        return qsTrId('id_unknown_firmware')
                    }
                    wrapMode: Label.WordWrap
                }
                ButtonGroup {
                    id: button_group
                }
                ListView {
                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredWidth: 325
                    ScrollIndicator.vertical: ScrollIndicator {}
                    clip: true
                    spacing: 0
                    model: {
                        const fws = []
                        for (const fw of update_controller.firmwares) {
                            if (fw.config !== config_selector.config) continue
                            if (!fw.compatible) continue
                            if (!left_item.checked) {
                                if (fw.has_delta) continue
                                if (!fw.upgrade) continue
                            }
                            fws.push(fw)
                        }
                        return fws.sort((a, b) => a.index < b.index ? 1 : a.index > b.index ? -1 : 0)
                    }
                    delegate: FirmwareButton {
                        focus: index === 0
                        firmware: modelData
                        topInset: 5
                        leftInset: 5
                        rightInset: 5
                        bottomInset: 5
                        width: ListView.view.width
                        ButtonGroup.group: button_group
                    }
                }
                PrimaryButton {
                    Layout.alignment: Qt.AlignCenter
                    Layout.minimumWidth: 325
                    Layout.topMargin: 20
                    enabled: button_group.checkedButton
                    text: qsTrId('id_continue')
                    onClicked: stack_view.push(confirm_update_view, { firmware: button_group.checkedButton.firmware })
                }
            }
        }
    }
/*
            ListView {
                Layout.alignment: Qt.AlignCenter
                Layout.minimumHeight: 400
                Layout.minimumWidth: 500
                ScrollIndicator.vertical: ScrollIndicator {}
                clip: true
                spacing: 10
                model: {
                    const fws = []
                    for (const fw of update_controller.firmwares) {
                        if (!show_all_checkbox.checked) {
                            if (!fw.upgrade) continue
                            if (!fw.compatible) continue
                            if (fw.has_delta) continue
                        }
                        fws.push(fw)
                    }
                    return fws
                }
                delegate: FirmwareButton {
                    id: yyy
                    leftPadding: 16
                    rightPadding: 16
                    property var firmware: modelData
                    width: ListView.view.width
                    ButtonGroup.group: button_group
                }
            }
            CheckBox {
                Layout.alignment: Qt.AlignCenter
                id: show_all_checkbox
                text: qsTrId('id_show_all')
            }
            VSpacer {
            }
        }
    }
*/
    Component {
        id: confirm_update_view
        ColumnLayout {
            required property var firmware
            StackView.onActivated: update_controller.update(view.firmware)
            id: view
            VSpacer {
            }
            GridLayout {
                Layout.fillWidth: false
                Layout.fillHeight: false
                Layout.alignment: Qt.AlignCenter
                columns: 2
                columnSpacing: 32
                rowSpacing: 12
                // visible: self.activity.status === Activity.Pending
                Label {
                    text: qsTrId('id_current_version') + ':'
                }
                Label {
                    text: firmwareVersionAndType(self.device.version, self.device.versionInfo["JADE_CONFIG"])
                }
                Label {
                    text: qsTrId('id_new_version') + ':'
                }
                Label {
                    text: firmwareVersionAndType(view.firmware.version, view.firmware.config)
                }
                Label {
                    text: qsTrId('id_hash')
                }
                Label {
                    text: {
                        const ge_0_1_46 = self.device.versionGreaterOrEqualThan('0.1.46')
                        const fwhash = view.firmware?.fwhash
                        const cmphash = view.firmware?.cmphash
                        const hash = String(ge_0_1_46 && fwhash ? fwhash : cmphash)
                        return ge_0_1_46 ? hash.match(/.{1,8}/g).join(' ') : hash
                    }
                    Layout.maximumWidth: 200
                    wrapMode: Label.WrapAnywhere
                }
            }
            BusyIndicator {
                Layout.alignment: Qt.AlignCenter
            }
            VSpacer {
            }
        }
    }

    Component {
        id: intialized_view
        JadeInitializedView {
            device: self.device
            onLoginFinished: (context) => stack_view.push(login_view, { context })
        }
    }

    Component {
        id: login_view
        JadeLoginView {
            onLoginFinished: (context) => self.loginFinished(context)
        }
    }

    Component {
        id: unintialized_view
        JadeUninitializedView {
            device: self.device
            onSetupFinished: (context) => stack_view.replace(null, login_view, { context }, StackView.PushTransition)
        }
    }

    component OptionButton: AbstractButton {
        property var tags: []
        Layout.alignment: Qt.AlignCenter
        Layout.minimumWidth: 325
        id: control
        checkable: true
        padding: 20
        background: Rectangle {
            color: Qt.lighter('#222226', control.down ? 1.5 : control.hovered ? 1.2 : 1)
            radius: 5
            border.width: control.checked ? 2 : 0
            border.color: '#00B45A'
            Rectangle {
                border.width: 2
                border.color: '#00B45A'
                color: 'transparent'
                radius: 9
                anchors.fill: parent
                anchors.margins: -4
                visible: control.visualFocus
            }
        }
        contentItem: RowLayout {
            spacing: constants.s1
            Label {
                Layout.fillWidth: true
                text: control.text
                font.pixelSize: 14
                font.weight: 600
            }
            Repeater {
                model: control.tags
                delegate: Label {
                    padding: 4
                    leftPadding: 8
                    rightPadding: 8
                    background: Rectangle {
                        border.color: modelData.color
                        border.width: 1
                        color: 'transparent'
                        radius: height / 2
                    }
                    text: modelData.text
                    font.pixelSize: 10
                    font.weight: 400
                    font.capitalization: Font.AllUppercase
                    color: modelData.color
                }
            }
        }
    }

    component FirmwareButton: OptionButton {
        property var firmware
        tags: {
            const tags = []
            if (firmware.latest) tags.push({ color: '#FFFFFF', text: 'LATEST' })
            if (firmware.channel === 'beta') tags.push({ color: '#dba5ff', text: 'BETA' })
            if (firmware.installed) tags.push({ color: constants.g300, text: qsTrId('id_current_version') })
            return tags
        }
        id: control
        text: control.firmware.version
        enabled: !control.firmware.installed
        checked: false
    }
}
