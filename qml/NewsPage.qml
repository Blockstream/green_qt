import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.15

Page {
    id: self

    NewsFeedController {
        id: controller
        Component.onCompleted: fetch()
    }

    background: null
    header: Label {
        text: "What's New at Blockstream"
        font.pixelSize: 18
        font.bold: true
        bottomPadding: constants.s1
    }
    contentItem: GFlickable {
        id: flickable
        contentWidth: layout.width
        contentHeight: height

        Row {
            height: flickable.height
            id: layout
            spacing: constants.p2
            Repeater {
                model: controller.model
                AbstractButton {
                    id: news_card
                    height: parent.height - constants.p2
                    implicitWidth: 350
                    padding: constants.p2
                    topPadding: height / 2 + constants.p2
                    background: Rectangle {
                        Image {
                            source: modelData.image
                            fillMode: Image.PreserveAspectCrop
                            smooth: true
                            mipmap: true
                            width: parent.width
                            height: parent.height / 2
                        }
                        color: news_card.hovered ? Qt.lighter(constants.c600, 1.25) : constants.c700
                        Behavior on color {
                            ColorAnimation {
                                duration: 100
                            }
                        }
                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: news_card.background.width
                                height: news_card.background.height
                                radius: 16
                            }
                        }
                        Rectangle {
                            border.color: parent.color
                            border.width: 1
                            radius: 16
                            color: 'transparent'
                            anchors.fill: parent
                        }
                        Image {
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 16
                            source: 'qrc:/svg/external_link.svg'
                            visible: news_card.hovered
                            width: 16
                            height: 16
                            smooth: true
                            mipmap: true
                        }
                    }
                    scale: news_card.down ? 0.95 : (news_card.hovered || news_card.activeFocus ? 1.01 : 1)
                    transformOrigin: Item.Center
                    Behavior on scale {
                        NumberAnimation {
                            easing.type: Easing.OutBack
                            duration: 400
                        }
                    }
                    onClicked: Qt.openUrlExternally(modelData.link)
                    clip: true
                    contentItem: ColumnLayout {
                        spacing: 8
                        Label {
                            Layout.fillWidth: true
                            text: modelData.title
                            color: 'white'
                            font.pixelSize: 14
                            font.bold: true
                            elide: Label.ElideRight
                        }
                        RowLayout {
                            Label {
                                Layout.fillWidth: true
                                text: new Date(modelData.pubDate).toLocaleString(Settings.language)
                                color: 'white'
                                opacity: 0.8
                                font.pixelSize: 10
                                elide: Label.ElideRight
                            }
                            Label {
                                text: modelData.category.replace('blockstream-', '')
                                color: 'black'
                                opacity: 0.8
                                font.pixelSize: 8
                                font.capitalization: Font.AllUppercase
                                elide: Label.ElideRight
                                topPadding: 2
                                bottomPadding: 2
                                leftPadding: 8
                                rightPadding: 8
                                background: Rectangle {
                                    color: 'white'
                                    radius: height / 2
                                }
                            }
                        }
                        Label {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            text: modelData.description
                            wrapMode: Label.WordWrap
                            elide: Label.ElideRight
                            color: "white"
                            font.pixelSize: 12
                            clip: true
                        }
                    }
                }
            }
        }
    }
}
