import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    required property Context context
    id: self
    background: null

    component InfoCard: Pane {
        required property string iconSource
        required property string title
        required property string description
        required property list<Component> linkButtons

        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredWidth: 0
        Layout.preferredHeight: 220

        background: Rectangle {
            color: '#181818'
            border.color: '#262626'
            border.width: 1
            radius: 4
        }

        contentItem: ColumnLayout {
            spacing: 8

            Image {
                source: iconSource
            }

            Label {
                text: title
                font.pixelSize: 20
                font.weight: 600
                color: '#FFFFFF'
            }

            Label {
                Layout.topMargin: -8
                text: description
                font.pixelSize: 14
                color: '#A0A0A0'
                wrapMode: Label.Wrap
            }

            ColumnLayout {
                spacing: 8

                Repeater {
                    model: linkButtons
                    delegate: Loader {
                        Layout.fillWidth: true
                        sourceComponent: modelData
                    }
                }
            }
        }
    }

    contentItem: VFlickable {
        alignment: Qt.AlignTop
        RowLayout {
            Layout.fillHeight: false
            spacing: 32
            InfoCard {
                iconSource: 'qrc:/svg3/questions.svg'
                title: 'FAQ'
                description: 'Quick answers to common questions'
                linkButtons: [
                    Component {
                        LinkButton {
                            text: 'Why is my transaction slow?'
                            font.pixelSize: 14
                        }
                    },
                    Component {
                        LinkButton {
                            text: 'Why do I have to pay transaction fees?'
                            font.pixelSize: 14
                        }
                    },
                    Component {
                        LinkButton {
                            text: 'Why does my receive address change?'
                            font.pixelSize: 14
                        }
                    }
                ]
            }

            InfoCard {
                iconSource: 'qrc:/svg3/key.svg'
                title: 'Key Terms'
                description: 'Important concepts for understanding your wallet'
                linkButtons: [
                    Component {
                        LinkButton {
                            text: 'Recovery phrase'
                            font.pixelSize: 14
                        }
                    },
                    Component {
                        LinkButton {
                            text: 'Software vs Hardware wallet'
                            font.pixelSize: 14
                        }
                    },
                    Component {
                        LinkButton {
                            text: 'Network types'
                            font.pixelSize: 14
                        }
                    }
                ]
            }
        }
        VSpacer {
            Layout.minimumHeight: 40
        }
    }
}
