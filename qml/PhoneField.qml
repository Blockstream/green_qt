import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

TTextField {
    readonly property string phone: '+' + self.country.code + self.text
    property var country: {
        for (let i = 0; i < countries.count; i++) {
            const data = countries.get(i)
            if (data.country === Settings.country) {
                return data
            }
        }
        return countries.get(0)
    }
    id: self
    leftPadding: country_button.width + 15
    Countries {
        id: countries
    }
    AbstractButton {
        id: country_button
        leftPadding: 6
        rightPadding: 6
        bottomPadding: 4
        topPadding: 4
        anchors.left: parent.left
        anchors.leftMargin: 15
        anchors.verticalCenter: parent.verticalCenter
        contentItem: RowLayout {
            spacing: 4
            Label {
                color: '#00BCFF'
                font: self.font
                text: '+' + self.country.code
            }
            Image {
                Layout.alignment: Qt.AlignCenter
                source: 'qrc:/svg2/caret-down.svg'
            }
        }
        onClicked: countries_menu.visible ? countries_menu.close() : countries_menu.open()
        background: Rectangle {
            border.width: 2
            border.color: '#00BCFF'
            color: 'transparent'
            visible: country_button.visualFocus
        }
        GMenu {
            id: countries_menu
            x: country_button.width * 0.5 - countries_menu.width * 0.1
            y: country_button.height + 8
            pointerX: 0.1
            pointerY: 0
            font: self.font
            Repeater {
                model: countries
                delegate: GMenu.Item {
                    hideIcon: true
                    details: ({ text: name, count: '+' + code })
                    onClicked: {
                        countries_menu.close()
                        self.country = model
                    }
                }
            }
        }
    }
}
