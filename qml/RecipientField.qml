import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

GTextArea {
    property string input
    property string previousText: ''
    property var recipient: parser.recipient
    Layout.fillWidth: true
    Layout.minimumHeight: 200
    id: field
    focus: true
    rightPadding: 15
    bottomPadding: 50
    RecipientParser {
        id: parser
        input: field.text.trim()
    }
    RowLayout {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottomMargin: 13
        anchors.leftMargin: 15
        anchors.rightMargin: 15
        spacing: 10
        CircleButton {
            activeFocusOnTab: false
            icon.source: 'qrc:/svg2/paste.svg'
            onClicked: {
                field.clear()
                field.paste()
            }
        }
        CircleButton {
            activeFocusOnTab: false
            enabled: scanner_popup.available && !scanner_popup.visible
            icon.source: 'qrc:/svg2/qrcode.svg'
            onClicked: scanner_popup.requestPermissionAndOpen()
            ScannerPopup {
                id: scanner_popup
                onCodeScanned: (code) => {
                    field.input = 'scan'
                    field.text = code
                }
            }
        }
        HSpacer {
        }
        CircleButton {
            enabled: field.text.length > 0
            activeFocusOnTab: false
            icon.source: 'qrc:/svg2/x-circle.svg'
            onClicked: {
                field.clear()
            }
        }
    }
    onTextChanged: {
        field.input = field.text.length === 0 ? '' : Math.abs(field.previousText.length - field.text.length) > 1 ? 'paste' : 'type'
        field.previousText = field.text
    }
}
