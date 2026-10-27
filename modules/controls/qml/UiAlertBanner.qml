import Blockstream.Theme
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    enum Variant { Negative, Warning, Info }

    signal dismissed()

    property int variant: UiAlertBanner.Info
    property string description: ""
    property string iconName: ""
    property bool dismissible: false
    property bool disabled: false
    property Colors colors: Theme.colors

    default property alias footerData: footer_column.data

    readonly property string resolvedIconName: {
        if (self.iconName.length > 0) return self.iconName
        if (self.variant === UiAlertBanner.Negative) return Theme.icons.warningDiamondFilled
        if (self.variant === UiAlertBanner.Warning) return Theme.icons.warningFilled
        return Theme.icons.infoFilled
    }

    readonly property color fillColor: {
        if (self.variant === UiAlertBanner.Negative) return self.colors.feedbackNegativeFill
        if (self.variant === UiAlertBanner.Warning) return self.colors.feedbackWarningFill
        return self.colors.feedbackInfoFill
    }

    readonly property color strokeColor: {
        if (self.variant === UiAlertBanner.Negative) return self.colors.feedbackNegativeStroke
        if (self.variant === UiAlertBanner.Warning) return self.colors.feedbackWarningStroke
        return self.colors.feedbackInfoStroke
    }

    readonly property color accentColor: {
        if (self.variant === UiAlertBanner.Negative) return self.colors.feedbackNegativeAccent
        if (self.variant === UiAlertBanner.Warning) return self.colors.feedbackWarningAccent
        return self.colors.feedbackInfoAccent
    }

    property bool hasFooter: false

    readonly property real footerLeading: 24 + 12
    readonly property real footerTrailing: self.dismissible ? dismiss_button.implicitWidth + 12 : 0

    function syncFooter() {
        self.hasFooter = footer_column.children.length > 0
        for (let i = 0; i < footer_column.children.length; ++i) {
            const child = footer_column.children[i]
            child.width = Qt.binding(() => Math.min(child.implicitWidth, footer_column.width))
        }
    }

    id: self
    header: null
    spacing: self.hasFooter ? 12 : 0
    leftPadding: 16
    rightPadding: 12
    topPadding: 12
    bottomPadding: 0
    implicitWidth: Math.max(self.implicitContentWidth + self.leftPadding + self.rightPadding, 200)
    focusPolicy: Qt.NoFocus
    // Cocoa omits the AlertMessage container and its runtime ID.
    Accessible.role: Qt.platform.os === 'osx' ? Accessible.Grouping : Accessible.AlertMessage
    Accessible.name: self.title.length > 0 ? self.title : self.description
    Accessible.description: self.title.length > 0 ? self.description : ''

    background: Rectangle {
        color: self.fillColor
        border.width: 1
        border.color: self.strokeColor
        radius: 8
    }

    contentItem: ColumnLayout {
        spacing: 0

        RowLayout {
            id: content_row
            Layout.fillWidth: true
            spacing: 12

            UiIcon {
                Layout.alignment: Qt.AlignTop
                name: self.resolvedIconName
                size: 24
                color: self.accentColor
            }

            ColumnLayout {
                id: text_column
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                Layout.alignment: Qt.AlignTop
                spacing: 0
                visible: self.title.length > 0 || self.description.length > 0

                UiLabel {
                    Layout.fillWidth: true
                    visible: self.title.length > 0
                    text: self.title
                    typography: Theme.typography.labelLSemibold
                    color: self.colors.textPrimary
                    wrapMode: Text.Wrap
                    Accessible.ignored: true
                }
                UiLabel {
                    Layout.fillWidth: true
                    visible: self.description.length > 0
                    text: self.description
                    typography: Theme.typography.bodyM
                    color: self.colors.textSubtle
                    wrapMode: Text.Wrap
                    Accessible.ignored: true
                }
            }

            UiIconButton {
                id: dismiss_button
                Accessible.id: self.Accessible.id ? self.Accessible.id + '_dismiss_btn' : ''
                Layout.alignment: Qt.AlignTop
                visible: self.dismissible
                size: UiButton.ExtraSmall
                variant: UiButton.Neutral
                colors: self.colors
                iconName: Theme.icons.x
                disabled: self.disabled
                Accessible.name: qsTrId('id_close')
                onClicked: self.dismissed()
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: self.hasFooter ? 0 : 16
        }
    }

    footer: Item {
        id: footer_host
        visible: self.hasFooter
        height: self.hasFooter ? footer_column.implicitHeight + 16 : 0
        implicitHeight: height

        Column {
            id: footer_column
            x: self.leftPadding + self.footerLeading
            width: Math.max(0, footer_host.width - self.leftPadding - self.rightPadding - self.footerLeading - self.footerTrailing)
            spacing: 0
            onChildrenChanged: Qt.callLater(self.syncFooter)
            Component.onCompleted: self.syncFooter()
        }
    }
}
