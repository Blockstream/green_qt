import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import "util.js" as UtilJS

MainPage {
    id: self

    SignupController {
        id: controller
        pin: '111111'
        network: NetworkManager.network('electrum-mainnet')
    }

    Image {
        parent: self.background
        source: 'qrc:/svg2/onboard_background.svg'
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
    }

    GStackView {
        id: stack_view
        anchors.fill: parent
        anchors.margins: 60
        initialItem: TosView {
        }
    }

    Component {
        id: add_wallet_view
        AddWalletView {
        }
    }

    Component {
        id: info_view
        InfoView {
        }
    }

    Component {
        id: recovery_phrase_backup_view
        RecoveryPhraseBackupView {
        }
    }

    Component {
        id: recovery_phrase_check_view
        RecoveryPhraseCheckView {
        }
    }

    Component {
        id: process_view
        GStackView.View {
            BusyIndicator {
                anchors.centerIn: parent
                running: true
            }
        }
    }

    component TosView: GStackView.View {
        contentItem: ColumnLayout {
            VSpacer {
                Layout.fillWidth: true
            }
            Pane {
                Layout.alignment: Qt.AlignCenter
                background: null
                contentItem: ColumnLayout {
                    spacing: 0
                    Image {
                        Layout.alignment: Qt.AlignCenter
                        source: 'qrc:/svg2/blockstream_green.svg'
                    }
                    Item {
                        Layout.minimumHeight: 20
                    }
                    Label {
                        Layout.alignment: Qt.AlignCenter
                        color: '#FFF'
                        font.family: 'SF Compact'
                        font.pixelSize: 30
                        font.weight: 656
                        horizontalAlignment: Label.AlignHCenter
                        text: 'Simple & Secure Self-Custody'
                    }
                    Item {
                        Layout.minimumHeight: 10
                    }
                    Label {
                        Layout.alignment: Qt.AlignCenter
                        Layout.fillWidth: true
                        font.family: 'SF Compact Display'
                        font.pixelSize: 14
                        font.weight: 400
                        horizontalAlignment: Label.AlignHCenter
                        opacity: 0.6
                        text: 'Everything you need to take control of your bitcoin.'
                        wrapMode: Label.WordWrap
                    }
                    Item {
                        Layout.minimumHeight: 50
                    }
                    AbstractButton {
                        Layout.alignment: Qt.AlignCenter
                        enabled: tos_check_box.checked
                        implicitHeight: 50
                        implicitWidth: 325
                        background: Rectangle {
                            color: '#50B163'
                            radius: 4
                        }
                        contentItem: Label {
                            horizontalAlignment: Qt.AlignHCenter
                            verticalAlignment: Qt.AlignVCenter
                            font.family: 'SF Compact'
                            font.pixelSize: 12
                            font.weight: 556
                            text: 'Add Wallet'
                        }
                        onClicked: stack_view.push(add_wallet_view) // .stack_layout.currentIndex = 1
                    }
                    Item {
                        Layout.minimumHeight: 10
                    }
                    AbstractButton {
                        Layout.alignment: Qt.AlignCenter
                        enabled: tos_check_box.checked
                        implicitHeight: 50
                        implicitWidth: 325
                        background: Rectangle {
                            color: '#141618'
                            radius: 4
                            border.width: 1
                            border.color: '#FFF'
                        }
                        contentItem: Label {
                            horizontalAlignment: Qt.AlignHCenter
                            verticalAlignment: Qt.AlignVCenter
                            font.family: 'SF Compact'
                            font.pixelSize: 12
                            font.weight: 556
                            text: 'Use Hardware Device'
                        }
                    }
                    Item {
                        Layout.minimumHeight: 20
                    }
                    RowLayout {
                        Layout.alignment: Qt.AlignCenter
                        Layout.fillWidth: false
                        Layout.fillHeight: false
                        spacing: 10
                        CheckBox {
                            id: tos_check_box
                            Layout.alignment: Qt.AlignCenter
                            bottomInset: 0
                            topInset: 0
                            leftInset: 0
                            rightInset: 0
                            checked: false
                        }
                        Label {
                            id: tos_label
                            Layout.alignment: Qt.AlignCenter
                            font.family: 'SF Compact Display'
                            font.pixelSize: 14
                            font.weight: 600
                            textFormat: Text.RichText
//                            text: qsTrId('id_i_agree_to_the') + ' ' + UtilJS.link('https://blockstream.com/green/terms/', qsTrId('id_terms_of_service'))
                            onLinkActivated: (link) => { Qt.openUrlExternally(link) }
                            text: 'I agree to the %1 and %2'.arg(UtilJS.link('https://blockstream.com/green/terms/', qsTrId('id_terms_of_service'))).arg(UtilJS.link('https://blockstream.com/green/terms/', qsTrId('Privacy Policy')))
                        }
                    }
                }
            }
            VSpacer {
            }
        }
    }

    component AddWalletView: GStackView.View {
        contentItem: ColumnLayout {
            VSpacer {
                Layout.fillWidth: true
            }
            Pane {
                Layout.alignment: Qt.AlignCenter
                background: null
                contentItem: ColumnLayout {
                    spacing: 0
                    Image {
                        Layout.alignment: Qt.AlignCenter
                        source: 'qrc:/svg2/take_control.svg'
                    }
                    Item {
                        Layout.minimumHeight: 20
                    }
                    Label {
                        Layout.alignment: Qt.AlignCenter
                        color: '#FFF'
                        font.family: 'SF Compact'
                        font.pixelSize: 35
                        font.weight: 656
                        horizontalAlignment: Label.AlignHCenter
                        text: 'Take Control: Your Keys, Your Bitcoin'
                    }
                    Item {
                        Layout.minimumHeight: 10
                    }
                    Label {
                        Layout.alignment: Qt.AlignCenter
                        color: '#FFF'
                        font.family: 'SF Compact Display'
                        font.pixelSize: 22
                        font.weight: 400
                        horizontalAlignment: Label.AlignHCenter
                        opacity: 0.6
                        text: 'Everything you need to take control of your bitcoin.'
                    }
                    Item {
                        Layout.minimumHeight: 80
                    }
                    AbstractButton {
                        Layout.alignment: Qt.AlignCenter
                        implicitHeight: 50
                        implicitWidth: 325
                        background: Rectangle {
                            color: '#50B163'
                            radius: 4
                        }
                        contentItem: Label {
                            horizontalAlignment: Qt.AlignHCenter
                            verticalAlignment: Qt.AlignVCenter
                            font.family: 'SF Compact'
                            font.pixelSize: 12
                            font.weight: 556
                            text: 'New Wallet'
                        }
                        onClicked: stack_view.push(info_view)
                    }
                    Item {
                        Layout.minimumHeight: 10
                    }
                    AbstractButton {
                        Layout.alignment: Qt.AlignCenter
                        implicitHeight: 50
                        implicitWidth: 325
                        background: Rectangle {
                            color: '#50B163'
                            radius: 4
                        }
                        contentItem: Label {
                            horizontalAlignment: Qt.AlignHCenter
                            verticalAlignment: Qt.AlignVCenter
                            font.family: 'SF Compact'
                            font.pixelSize: 12
                            font.weight: 556
                            text: 'Restore Wallet'
                        }
                    }
                    Item {
                        Layout.minimumHeight: 10
                    }
                    AbstractButton {
                        Layout.alignment: Qt.AlignCenter
                        implicitHeight: 50
                        implicitWidth: 325
                        background: Rectangle {
                            color: '#141618'
                            radius: 4
                            border.width: 1
                            border.color: '#FFF'
                        }
                        contentItem: Label {
                            horizontalAlignment: Qt.AlignHCenter
                            verticalAlignment: Qt.AlignVCenter
                            font.family: 'SF Compact'
                            font.pixelSize: 12
                            font.weight: 556
                            text: 'Watch-Only'
                        }
                    }
                }
            }
        }
        VSpacer {
        }
    }

    component InfoView: GStackView.View {
        contentItem: ColumnLayout {
            RowLayout {
                BackButton {
                    onClicked: stack_view.pop()
                }
                HSpacer {
                }
            }
            VSpacer {
            }
            Pane {
                Layout.alignment: Qt.AlignCenter
                background: null
                contentItem: ColumnLayout {
                    spacing: 0
                    width: 325
                    Label {
                        Layout.fillWidth: true
                        color: '#FFF'
                        font.family: 'SF Compact Display'
                        font.pixelSize: 14
                        font.weight: 500
                        horizontalAlignment: Qt.AlignHCenter
                        text: 'Before You Backup'
                    }
                    Item {
                        Layout.minimumHeight: 36
                    }
                    InfoCard {
                        icon: 'qrc:/svg2/house.svg'
                        title: 'Safe Environment'
                        description: 'Make sure you are alone and no camera is recording you or the screen.'
                    }
                    Item {
                        Layout.minimumHeight: 10
                    }
                    InfoCard {
                        icon: 'qrc:/svg2/warning.svg'
                        title: 'Sensitive Information'
                        description: 'Whomever can access your recovery phrase, can steal your funds.'
                    }
                    Item {
                        Layout.minimumHeight: 10
                    }
                    InfoCard {
                        icon: 'qrc:/svg2/shield_check.svg'
                        title: 'Safely stored'
                        description: 'If you forget it or lose it, your funds are going to be lost as well.'
                    }
                    Item {
                        Layout.minimumHeight: 39
                    }
                    AbstractButton {
                        Layout.alignment: Qt.AlignCenter
                        implicitHeight: 50
                        implicitWidth: 325
                        background: Rectangle {
                            color: '#50B163'
                            radius: 4
                        }
                        contentItem: Label {
                            horizontalAlignment: Qt.AlignHCenter
                            verticalAlignment: Qt.AlignVCenter
                            font.family: 'SF Compact'
                            font.pixelSize: 12
                            font.weight: 556
                            text: 'Show Recovery Phrase'
                        }
                        onClicked: stack_view.push(recovery_phrase_backup_view)
                    }
                    Item {
                        Layout.minimumHeight: 40
                    }
                    AbstractButton {
                        Layout.alignment: Qt.AlignCenter
                        background: null
                        contentItem: RowLayout {
                            spacing: 10
                            HSpacer {
                            }
                            Image {
                                source: 'qrc:/svg2/printer.svg'
                            }
                            Label {
                                color: '#FFF'
                                font.family: 'SF Compact'
                                font.pixelSize: 12
                                font.weight: 556
                                text: 'Print Backup Template'
                            }
                            HSpacer {
                            }
                        }
                    }
                }
            }
            VSpacer {
            }
        }
    }

    property int size: 12
    component RecoveryPhraseBackupView: GStackView.View {
        contentItem: ColumnLayout {
            RowLayout {
                BackButton {
                    onClicked: stack_view.pop()
                }
                HSpacer {
                }
                Image {
                    source: 'qrc:/svg2/printer.svg'
                }
                Label {
                    color: '#FFF'
                    font.family: 'SF Compact'
                    font.pixelSize: 12
                    font.weight: 556
                    text: 'Print Backup Template'
                }
            }
            VSpacer {
            }
            Pane {
                Layout.alignment: Qt.AlignCenter
                background: null
                contentItem: ColumnLayout {
                    spacing: 0
                    Label {
                        Layout.alignment: Qt.AlignCenter
                        font.family: 'SF Compact Display'
                        font.pixelSize: 24
                        font.weight: 600
                        textFormat: Label.RichText
                        text: 'Write down your <span style="color: #2FD058">recovery phrase</span> in the <span style="color: #2FD058">correct order</span>'
                    }
                    Item {
                        Layout.minimumHeight: 20
                    }
                    Label {
                        Layout.alignment: Qt.AlignCenter
                        font.family: 'SF Compact Display'
                        font.pixelSize: 14
                        font.weight: 600
                        opacity: 0.4
                        text: 'Store it somewhere safe.'
                    }
                    Item {
                        Layout.minimumHeight: 20
                    }
                    Pane {
                        Layout.alignment: Qt.AlignCenter
                        padding: 0
                        background: Rectangle {
                            border.width: 0.5
                            border.color: '#313131'
                            color: '#121414'
                            radius: 4
                        }
                        contentItem: RowLayout {
                            spacing: 0
                            AbstractButton {
                                id: b12
                                checked: self.size === 12
                                implicitHeight: 35
                                implicitWidth: 163
                                background: Rectangle {
                                    opacity: b12.checked ? 1 : 0
                                    Behavior on opacity {
                                        NumberAnimation { duration: 300 }
                                    }
                                    border.width: b12.checked ? 1 : 0.5
                                    border.color: Qt.alpha('#FFF', 0.3)
                                    color: '#3A3A3D'
                                    radius: 4
                                }
                                contentItem: Label {
                                    font.family: 'SF Compact Display'
                                    font.pixelSize: 12
                                    font.weight: 600
                                    horizontalAlignment: Label.AlignHCenter
                                    verticalAlignment: Label.AlignVCenter
                                    opacity: b12.checked ? 1 : 0.3
                                    Behavior on opacity {
                                        NumberAnimation { duration: 300 }
                                    }
                                    text: '12 Words'
                                }
                                onClicked: self.size = 12
                            }
                            AbstractButton {
                                id: b24
                                checked: self.size === 24
                                implicitHeight: 35
                                implicitWidth: 163
                                background: Rectangle {
                                    opacity: b24.checked ? 1 : 0
                                    Behavior on opacity {
                                        NumberAnimation { duration: 300 }
                                    }
                                    border.width: b24.checked ? 1 : 0.5
                                    border.color: Qt.alpha('#FFF', 0.3)
                                    color: '#3A3A3D'
                                    radius: 4
                                }
                                contentItem: Label {
                                    font.family: 'SF Compact Display'
                                    font.pixelSize: 12
                                    font.weight: 600
                                    horizontalAlignment: Label.AlignHCenter
                                    verticalAlignment: Label.AlignVCenter
                                    opacity: b24.checked ? 1 : 0.3
                                    Behavior on opacity {
                                        NumberAnimation { duration: 300 }
                                    }
                                    text: '24 Words'
                                }
                                onClicked: self.size = 24
                            }
                        }
                    }
                    Item {
                        Layout.minimumHeight: 20
                    }
                    Pane {
                        Layout.alignment: Qt.AlignCenter
                        background: null
                        contentItem: MnemonicView {
                            id: mnemonic_view
                            rows: 6
                            mnemonic: controller.generateMnemonic(self.size)
                        }
                    }
                    Item {
                        Layout.minimumHeight: 30
                    }
                    Btn {
                        Layout.alignment: Qt.AlignCenter
                        text: 'Next'
                        onClicked: {
                            controller.mnemonic = mnemonic_view.mnemonic
                            stack_view.push(recovery_phrase_check_view)
                        }
                    }
                    Item {
                        Layout.minimumHeight: 18
                    }
                }
            }
            VSpacer {
            }
            Image {
                Layout.alignment: Qt.AlignCenter
                source: 'qrc:/svg2/house.svg'
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                font.family: 'SF Compact Display'
                font.pixelSize: 12
                font.weight: 600
                text: 'Make sure to be in a private and safe space'
            }
        }
    }

    component RecoveryPhraseCheckView: GStackView.View {
        contentItem: ColumnLayout {
            id: xxxx
            readonly property bool checked: {
                if (check_repeater.count === 0) return false
                for (let i = 0; i < check_repeater.count; i++) {
                    if (!check_repeater.itemAt(i).match) {
                        return false
                    }
                }
                return true
            }

            onCheckedChanged: {
                console.log('checked changed', checked)
                if (checked) {
                    stack_view.push(process_view)
                }
            }

            RowLayout {
                BackButton {
                    onClicked: stack_view.pop()
                }
                HSpacer {
                }
            }
            VSpacer {
            }
            Pane {
                Layout.alignment: Qt.AlignCenter
                background: null
                contentItem: ColumnLayout {
                    spacing: 0
                    Label {
                        Layout.alignment: Qt.AlignCenter
                        font.family: 'SF Compact Display'
                        font.pixelSize: 24
                        font.weight: 600
                        text: 'Recovery Phrase Check'
                    }
                    Item {
                        Layout.minimumHeight: 20
                    }
                    Item {
                        Layout.minimumHeight: 20
                    }
                    Label {
                        Layout.alignment: Qt.AlignCenter
                        font.family: 'SF Compact Display'
                        font.pixelSize: 14
                        font.weight: 600
                        opacity: 0.4
                        text: 'Make sure you got everything right'
                    }
                    Item {
                        Layout.minimumHeight: 30
                    }
                    VSpacer {
                    }
                    ColumnLayout {
                        spacing: 10
                        Repeater {
                            id: check_repeater
                            model: {
                                const count = 6
                                const size = controller.mnemonic.length
                                const indexes = [...Array(size).keys()]
                                const result = []
                                while (result.length < count) {
                                    const remove = indexes.length * Math.random()
                                    const [index] = indexes.splice(remove, 1)
                                    result.push(index)
                                }
                                return result.sort((a, b) => a - b)//.map(index => ({ index, word: controller.mnemonic[index] }))
                            }
                            delegate: Collapsible {
                                id: word_checker
                                readonly property int word: modelData
                                readonly property bool match: controller.mnemonic[word_checker.word] === check_field.text
                                Layout.fillWidth: true
                                collapsed: index > 0 && !check_repeater.itemAt(index - 1).match
                                contentHeight: check_field.implicitHeight
                                TextField {
                                    width: parent.width
                                    id: check_field
                                    enabled: !word_checker.match
                                    padding: 15
                                    topPadding: 15
                                    bottomPadding: 15
                                    bottomInset: 0
                                    leftPadding: 50
                                    rightPadding: 40
                                    font.family: 'SF Compact Display'
                                    font.pixelSize: 14
                                    font.weight: 400
                                    focus: !parent.collapsed && !parent.match
                                    placeholderText: controller.mnemonic[word_checker.word]
                                    background: Rectangle {
                                        radius: 5
                                        color: '#222226'
                                        Label {
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left: parent.left
                                            anchors.margins: 15
                                            font.family: 'SF Compact Display'
                                            font.pixelSize: 14
                                            font.weight: 700
                                            text: word_checker.word + 1
                                        }
                                        Image {
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.right: parent.right
                                            anchors.margins: 15
                                            source: 'qrc:/svg2/check-green.svg'
                                            opacity: word_checker.match ? 1 : 0
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
                    }
                    Item {
                        Layout.minimumHeight: 30
                    }
                }
            }
            VSpacer {
            }
            Image {
                Layout.alignment: Qt.AlignCenter
                source: 'qrc:/svg2/house.svg'
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                font.family: 'SF Compact Display'
                font.pixelSize: 12
                font.weight: 600
                text: 'Make sure to be in a private and safe space'
            }
        }
    }

    component InfoCard: Pane {
        property alias icon: icon_image.source
        property alias title: title_label.text
        property alias description: description_label.text

        Layout.fillWidth: true
        Layout.maximumWidth: 325
        background: Rectangle {
            radius: 4
            color: '#222226'
        }
        leftPadding: 50
        rightPadding: 50
        contentItem: ColumnLayout {
            Image {
                id: icon_image
                Layout.alignment: Qt.AlignCenter
            }
            Label {
                id: title_label
                Layout.fillWidth: true
                color: '#FFF'
                font.family: 'SF Compact Display'
                font.pixelSize: 14
                font.weight: 700
                horizontalAlignment: Qt.AlignHCenter
                text: 'Safe Environment'
                wrapMode: Label.WordWrap
            }
            Label {
                id: description_label
                Layout.fillWidth: true
                color: '#FFF'
                opacity: 0.6
                font.family: 'SF Compact Display'
                font.pixelSize: 12
                font.weight: 400
                horizontalAlignment: Qt.AlignHCenter
                text: 'Make sure you are alone and no camera is recording you or the screen.'
                wrapMode: Label.WordWrap
            }
        }
    }

    component Btn: AbstractButton {
        id: btn
        implicitHeight: 50
        implicitWidth: 325
        background: Rectangle {
            color: '#50B163'
            radius: 4
        }
        contentItem: Label {
            horizontalAlignment: Qt.AlignHCenter
            verticalAlignment: Qt.AlignVCenter
            font.family: 'SF Compact'
            font.pixelSize: 12
            font.weight: 556
            text: btn.text
        }
    }
}
