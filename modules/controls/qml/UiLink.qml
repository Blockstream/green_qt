import Blockstream.Theme
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

AbstractButton {
    enum Size { Large, Medium }

    signal linkActivated(url url)

    property int size: UiLink.Large
    property url url
    property string iconName: Theme.icons.arrowSquareOut
    property bool disabled: false
    property Colors colors: Theme.colors

    readonly property bool activatable: self.enabled && self.url.toString().length > 0
    readonly property TypographyStyle typography: self.size === UiLink.Medium ? Theme.typography.labelMMedium : Theme.typography.labelLMedium
    readonly property bool interactionHovered: self.activatable && !self.visualFocus && self.hovered

    readonly property color foregroundColor: {
        if (!self.enabled) return self.colors.textDisabled
        return self.interactionHovered ? self.colors.textBrandHover : self.colors.textBrand
    }

    readonly property color iconColor: {
        if (!self.enabled) return self.colors.iconDisabled
        return self.interactionHovered ? self.colors.textBrandHover : self.colors.iconBrand
    }

    function activate() {
        if (!self.activatable) return
        self.linkActivated(self.url)
        Qt.openUrlExternally(self.url)
    }

    id: self
    implicitWidth: self.implicitContentWidth + self.leftPadding + self.rightPadding
    implicitHeight: self.implicitContentHeight + self.topPadding + self.bottomPadding
    padding: 0
    enabled: !self.disabled
    focusPolicy: Qt.StrongFocus
    hoverEnabled: true
    font: Qt.font({
        family: self.typography.family,
        pixelSize: self.typography.pixelSize,
        weight: self.typography.weight,
        letterSpacing: self.typography.letterSpacing,
        capitalization: self.typography.capitalization,
        underline: true
    })
    Accessible.role: Accessible.Link
    Accessible.name: self.text
    onClicked: self.activate()
    Keys.onReturnPressed: (event) => {
        if (!event.isAutoRepeat) self.activate()
    }
    Keys.onEnterPressed: (event) => {
        if (!event.isAutoRepeat) self.activate()
    }

    HoverHandler {
        enabled: self.activatable
        cursorShape: Qt.PointingHandCursor
    }

    // Outside the control bounds so focus does not change its size.
    background: Item {
        id: link_background
        Rectangle {
            anchors.fill: link_background
            anchors.margins: -4
            color: 'transparent'
            border.width: 2
            border.color: self.colors.borderFocus
            radius: 4
            visible: self.enabled && self.visualFocus
        }
    }

    contentItem: RowLayout {
        spacing: 4
        Text {
            id: link_text
            Layout.fillWidth: true
            Layout.preferredWidth: Math.ceil(link_text.implicitWidth)
            Layout.maximumWidth: Math.ceil(link_text.implicitWidth)
            text: self.text
            font: self.font
            color: self.foregroundColor
            lineHeightMode: Text.FixedHeight
            lineHeight: self.typography.lineHeight
            wrapMode: Text.Wrap
            Accessible.ignored: true
        }
        UiIcon {
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: (self.typography.lineHeight - 16) / 2
            name: self.iconName
            size: 16
            color: self.iconColor
        }
    }
}
