import Blockstream.Controls
import Blockstream.Testing
import Blockstream.Theme
import QtQuick
import QtTest

GreenTestCase {
    id: test_case
    name: "tst_uialertbanner"
    when: windowShown
    width: 400
    height: 240

    property int actionClicks: 0

    Component {
        id: banner_component
        UiAlertBanner {
            width: 360
            title: "Back up your wallet"
            description: "Anyone with a copy of your recovery phrase can spend your funds."
        }
    }

    Component {
        id: banner_with_actions_component
        UiAlertBanner {
            width: 360
            title: "Payment failed"
            description: "Try again or open details."
            Row {
                spacing: 8
                UiButton {
                    size: UiButton.ExtraSmall
                    variant: UiButton.PrimaryInverted
                    text: "Try again"
                    onClicked: test_case.actionClicks += 1
                }
                UiButton {
                    size: UiButton.ExtraSmall
                    variant: UiButton.SecondaryInverted
                    text: "Details"
                    onClicked: test_case.actionClicks += 1
                }
            }
        }
    }

    Component {
        id: banner_with_long_link_component
        UiAlertBanner {
            width: 280
            dismissible: true
            title: "Learn more"
            description: "Help article"
            UiLink {
                size: UiLink.Medium
                text: "Open the full recovery phrase guide with a very long translated label"
                url: "https://help.blockstream.com/"
            }
        }
    }

    SignalSpy {
        id: dismiss_spy
        signalName: "dismissed"
    }

    function createBanner(properties = {}) {
        const banner = createTemporaryObject(banner_component, test_case, properties)
        verify(banner !== null)
        dismiss_spy.target = banner
        dismiss_spy.clear()
        return banner
    }

    function contentRow(banner) {
        return banner.contentItem.children[0]
    }

    function textColumn(banner) {
        return contentRow(banner).children[1]
    }

    function dismissButton(banner) {
        return contentRow(banner).children[2]
    }

    function footerColumn(banner) {
        return banner.footer.children[0]
    }

    function cleanup() {
        dismiss_spy.target = null
        test_case.actionClicks = 0
    }

    function test_variantColors_data() {
        return [
            {
                tag: "negative",
                variant: UiAlertBanner.Negative,
                fill: "feedbackNegativeFill",
                stroke: "feedbackNegativeStroke",
                accent: "feedbackNegativeAccent",
                icon: Theme.icons.warningDiamondFilled
            },
            {
                tag: "warning",
                variant: UiAlertBanner.Warning,
                fill: "feedbackWarningFill",
                stroke: "feedbackWarningStroke",
                accent: "feedbackWarningAccent",
                icon: Theme.icons.warningFilled
            },
            {
                tag: "info",
                variant: UiAlertBanner.Info,
                fill: "feedbackInfoFill",
                stroke: "feedbackInfoStroke",
                accent: "feedbackInfoAccent",
                icon: Theme.icons.infoFilled
            }
        ]
    }

    function test_variantColors(row) {
        const banner = createBanner({ variant: row.variant })
        compare(banner.fillColor, Theme.colors[row.fill])
        compare(banner.strokeColor, Theme.colors[row.stroke])
        compare(banner.accentColor, Theme.colors[row.accent])
        compare(banner.resolvedIconName, row.icon)
        banner.colors = Theme.lightColors
        compare(banner.fillColor, Theme.lightColors[row.fill])
        compare(banner.strokeColor, Theme.lightColors[row.stroke])
        compare(banner.accentColor, Theme.lightColors[row.accent])
    }

    function test_iconNameOverride() {
        const banner = createBanner({
            variant: UiAlertBanner.Info,
            iconName: Theme.icons.warning
        })
        compare(banner.resolvedIconName, Theme.icons.warning)
    }

    function test_descriptionWraps() {
        const banner = createBanner({
            title: "",
            description: "This is a long alert description that should wrap across multiple lines inside the constrained banner width without clipping the text content."
        })
        verify(banner.height > 48)
        const labels = textColumn(banner).children
        let description
        for (let i = 0; i < labels.length; ++i) {
            if (labels[i].text === banner.description)
                description = labels[i]
        }
        verify(description !== undefined)
        compare(description.wrapMode, Text.Wrap)
        compare(description.color, Theme.colors.textSubtle)
        verify(description.lineCount > 1)
        verify(!description.truncated)
    }

    function test_titleAndDescriptionColors() {
        const banner = createBanner()
        const labels = textColumn(banner).children
        compare(labels[0].color, Theme.colors.textPrimary)
        compare(labels[1].color, Theme.colors.textSubtle)
    }

    function test_footerChildren() {
        const banner = createTemporaryObject(banner_with_actions_component, test_case)
        verify(banner !== null)
        verify(banner.hasFooter)
        const column = footerColumn(banner)
        tryVerify(() => column.width > 0)
        const row = column.children[0]
        tryVerify(() => row.width > 0)
        verify(row.width <= column.width)
        verify(row.children.length === 2)
        verify(row.children[0].width < column.width)
        row.children[0].click()
        row.children[1].click()
        compare(test_case.actionClicks, 2)
    }

    function test_emptyFooterTakesNoSpace() {
        const without_footer = createBanner()
        const with_footer = createTemporaryObject(banner_with_actions_component, test_case)
        verify(with_footer !== null)
        verify(!without_footer.hasFooter)
        verify(with_footer.hasFooter)
        compare(without_footer.footer.visible, false)
        compare(without_footer.footer.height, 0)
        compare(without_footer.spacing, 0)
        tryVerify(() => with_footer.footer.height > 0)
        compare(with_footer.spacing, 12)
    }

    function test_longFooterLinkStaysWithinBanner() {
        const banner = createTemporaryObject(banner_with_long_link_component, test_case)
        verify(banner !== null)
        verify(banner.hasFooter)
        const column = footerColumn(banner)
        tryVerify(() => column.width > 0)
        const link = column.children[0]
        tryCompare(link, "width", column.width)
        verify(link.width > 0)
        verify(link.width <= banner.width - banner.leftPadding - banner.rightPadding)
    }

    function test_dismiss() {
        const banner = createBanner({ dismissible: true })
        const dismiss = dismissButton(banner)
        verify(dismiss.visible)
        mouseClick(dismiss)
        compare(dismiss_spy.count, 1)
    }

    function test_disabledBlocksDismiss() {
        const banner = createBanner({
            disabled: true,
            dismissible: true
        })
        mouseClick(dismissButton(banner))
        compare(dismiss_spy.count, 0)
    }

    function test_accessibility() {
        const banner = createBanner()
        compare(banner.Accessible.role, Accessible.AlertMessage)
        compare(banner.Accessible.name, "Back up your wallet")
        compare(banner.Accessible.description, "Anyone with a copy of your recovery phrase can spend your funds.")
    }
}
