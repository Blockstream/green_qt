import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.12

Page {
    id: self

    NewsFeedController {
        id: controller
        Component.onCompleted: fetch()
    }

    background: null
    header: RowLayout {
        Label {
            text: "What's New at Blockstream"
            font.pixelSize: 18
            font.bold: true
        }
        HSpacer {
        }
    }
    GFlickable {
        id: flickable
        anchors.fill: parent
        clip: true
        contentWidth: layout.width
        contentHeight: height

        Row {
            height: flickable.height
            id: layout
            spacing: constants.p2
            Repeater {
                model: controller.model
                Button {
                    id: news_card
                    height: parent.height - 12
                    implicitWidth: 400
                    padding: constants.p3

                    background: Rectangle {
                        radius: 4
                        color: news_card.hovered ? Qt.lighter(constants.c600, 1.25) : constants.c700
                        Behavior on color {
                            ColorAnimation {
                                duration: 100
                            }
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
                        spacing: constants.s1
                        Image {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.minimumHeight: 100
                            Layout.maximumHeight: 100
                            fillMode: Image.PreserveAspectCrop
                            smooth: true
                            mipmap: true
                            source: modelData.image
                        }
                        Label {
                            Layout.fillWidth: true
                            text: new Date(modelData.pubDate).toLocaleString(Settings.language)
                            color: 'white'
                            opacity: 0.8
                            font.pixelSize: 10
                            elide: Label.ElideRight
                        }
                        Label {
                            Layout.fillWidth: true
                            text: modelData.title
                            color: 'white'
                            font.pixelSize: 14
                            font.bold: true
                            elide: Label.ElideRight
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
