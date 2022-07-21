import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.15
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.15

Page {
    id: self

    BlogController {
        id: controller
        Component.onCompleted: fetch()
    }

    background: null
    header: RowLayout {
        Label {
            Layout.fillWidth: true
            text: "What's New at Blockstream"
            font.pixelSize: 18
            font.bold: true
            bottomPadding: constants.s1
        }
        BusyIndicator {
            Layout.preferredHeight: 32
            running: controller.fetching
            visible: running
            bottomPadding: constants.s1
        }
    }
    contentItem: ListView {
        ScrollBar.horizontal: ScrollBar {
            id: horizontal_scroll_bar
            policy: ScrollBar.AlwaysOn
            visible: list_view.contentWidth > list_view.width
            background: Rectangle {
                color: constants.c800
                radius: width / 2
            }
            contentItem: Rectangle {
                implicitHeight: constants.p0
                color: horizontal_scroll_bar.pressed ? constants.c400 : constants.c600
                radius: 8
            }
        }

        Keys.onLeftPressed: horizontal_scroll_bar.decrease()
        Keys.onRightPressed: horizontal_scroll_bar.increase()

        id: list_view
        model: controller.model
        spacing: constants.p2
        orientation: ListView.Horizontal
        displayMarginBeginning: 100
        displayMarginEnd: 100
        delegate: AbstractButton {
            id: news_card
            height: list_view.height - constants.p2
            implicitWidth: {
                const n = Math.ceil(list_view.width / 600)
                return (list_view.width - (n - 1) * list_view.spacing) / n
            }
            padding: constants.p3
            background: Rectangle {
                radius: 16
                color: constants.c800
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
            onClicked: Qt.openUrlExternally(post.link)
            contentItem: RowLayout {
                spacing: constants.s2
                ColumnLayout {
                    Label {
                        text: post.category
                        color: 'white'
                        opacity: 0.8
                        font.pixelSize: 10
                        font.capitalization: Font.AllUppercase
                        elide: Label.ElideRight
                    }
                    Label {
                        Layout.fillWidth: true
                        text: post.title
                        color: 'white'
                        font.pixelSize: 16
                        font.bold: true
                        elide: Label.ElideRight
                        wrapMode: Label.WordWrap
                    }
                    VSpacer {
                    }
                    Label {
                        Layout.fillWidth: true
                        text: post.publicationDate.toLocaleString(Settings.language)
                        color: 'white'
                        opacity: 0.8
                        font.pixelSize: 10
                        elide: Label.ElideRight
                    }
                }
                Image {
                    id: image
                    source: post.imagePath
                    fillMode: Image.PreserveAspectCrop
                    horizontalAlignment: Image.AlignLeft
                    verticalAlignment: Image.AlignTop
                    smooth: true
                    mipmap: true
                    asynchronous: true
                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredWidth: 140
                    Layout.preferredHeight: 140
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: image.width
                            height: image.height
                            radius: image.width / 2
                        }
                    }
                }
            }
        }
    }
}
