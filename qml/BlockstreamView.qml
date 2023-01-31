import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

MainPage {
    id: self

    property alias busy: controller.fetching
    property bool _first_view: true
    BlogController {
        id: controller
    }
    onVisibleChanged: {
        if (visible) {
            if (_first_view) controller.fetch()
            _first_view = false
        }
    }
    bottomPadding: constants.p2
    header: MainPageHeader {
        topPadding: constants.p4
        background: Rectangle {
            color: constants.c900
            FastBlur {
                anchors.fill: parent
                cached: true
                opacity: 0.5
                radius: 64
                source: ShaderEffectSource {
                    sourceItem: self.contentItem
                    sourceRect {
                        x: -self.contentItem.x
                        y: -self.contentItem.y
                        width: self.header.width
                        height: self.header.height
                    }
                }
            }
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: constants.c900
            }
        }
        contentItem: Label {
            text: "What's New at Blockstream"
            font.pixelSize: 18
            font.bold: true
            bottomPadding: constants.s1
        }
        TapHandler {
            onTapped: list_view.contentY = 0
        }
    }
    contentItem: ListView {
        id: list_view
        model: controller.model
        spacing: constants.p2
        displayMarginBeginning: 1000
        displayMarginEnd: 0
        delegate: AbstractButton {
            id: news_card
            height: 220
            implicitWidth: ListView.view.width - 16
            padding: constants.p3
            background: Rectangle {
                radius: 16
                color: constants.c800
                Image {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: constants.p3
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
                spacing: constants.s3
                ColumnLayout {
                    spacing: constants.s1
                    RowLayout {
                        Label {
                            text: post.category
                            color: 'white'
                            opacity: 0.8
                            font.pixelSize: 12
                            font.capitalization: Font.AllUppercase
                            elide: Label.ElideRight
                        }
                    }
                    Label {
                        Layout.fillWidth: true
                        text: post.title
                        color: 'white'
                        font.pixelSize: 18
                        font.bold: true
                        elide: Label.ElideRight
                        wrapMode: Label.WordWrap
                    }
                    Label {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        text: post.description
                        color: 'white'
                        font.pixelSize: 14
                        elide: Label.ElideRight
                        wrapMode: Label.WordWrap
                    }
                    Label {
                        Layout.fillWidth: true
                        text: post.publicationDate.toLocaleString(Settings.language)
                        color: 'white'
                        opacity: 0.8
                        font.pixelSize: 12
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
                    Layout.preferredWidth: 160
                    Layout.preferredHeight: 160
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
        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AlwaysOn
            visible: list_view.contentHeight > list_view.height
            background: Item {
            }
            contentItem: Rectangle {
                implicitWidth: 8
                color: constants.c700
                radius: 4
            }
        }
    }
}
