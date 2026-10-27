# QML conventions

These notes apply to QML under `qml/`. They are part of the repository agent instructions; start from [AGENTS.md](../../AGENTS.md).

## Import order

```qml
import Blockstream.Green       // Project imports first
import Blockstream.Green.Core
import Blockstream.Controls
import Blockstream.Theme
import QtQuick                 // Qt imports
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS     // Local JS imports last
import "analytics.js" as AnalyticsJS
```

## Component structure

```qml
ComponentType {
    signal mySignal()                          // Signals first
    required property Context context          // Required properties
    required property Account account
    property bool readonly: false              // Optional properties
    property Asset asset                       // with defaults
    readonly property string computed: {       // Computed readonly properties
        return self.context?.someValue ?? 'default'
    }

    function myFunction() { }                  // Functions before id

    id: self                                   // Always use 'self' for root id

    // Visual properties and bindings...
}
```

## ID naming

- **Root component**: Always `self`
- **Child elements**: `snake_case` (`amount_input`, `quote_fetch_timer`, `clear_button`)
- **Component definitions**: `snake_case_page` or `snake_case_view`

## Property patterns

```qml
// Required properties (must be set by parent)
required property Context context
required property Account account

// Optional with defaults
property bool readonly: false
property Asset asset

// Readonly computed properties
readonly property string currencyCode: {
    const currency = self.context?.primarySession?.settings?.pricing?.currency ?? 'USD'
    return currency.toLowerCase()
}

// Alias properties for child access
property alias contentItemData: layout.data
property alias leftItem: left_pane.contentItem
```

For short `if` returns in computed properties, keep the condition and `return` on one line. Use braces only when the line would be hard to read:

```qml
// Good: short one-liners
readonly property color fillColor: {
    if (self.variant === UiAlertBanner.Negative) return self.colors.feedbackNegativeFill
    if (self.variant === UiAlertBanner.Warning) return self.colors.feedbackWarningFill
    return self.colors.feedbackInfoFill
}

// Good: braces when the return expression is too long for one line
readonly property string label: {
    if (self.useDetailedLabel) {
        return qsTrId('id_a_very_long_translation_id_that_should_use_braces')
    }
    return qsTrId('id_name')
}
```

## Null-safe access

Prefer optional chaining and nullish coalescing for values that can be unset while pages are loading, sessions are switching, or models are rebuilding:

```qml
// Good
text: self.account?.network?.displayName ?? '-'
text: controller.transaction?.error?.length ?? 0

// Bad
text: self.account.network.displayName  // Binding error
```

## Layout patterns

```qml
// Prefer VFlickable for normal vertical page/form content.
// VFlickable handles width binding, scroll indicators, and clipping automatically.
// VFlickable uses ColumnLayout by default, so children can use Layout.* properties directly.
contentItem: VFlickable {
    alignment: Qt.AlignTop
    spacing: 5

    Label { }
    TextField { }
    VSpacer { }  // Push content up
}

// Use RowLayout/ColumnLayout with Layout.* attached properties
RowLayout {
    spacing: 10
    Label {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
    }
    HSpacer { }
    Button { }
}
```

Use plain `Flickable` only when the view needs custom sizing, nested delegates, non-column content, or behavior that `VFlickable` does not provide. Follow the nearest existing page when choosing between them.

## Design system foundations

For new UI, use the `Theme` singleton from `Blockstream.Theme` and the `Ui*` components from `Blockstream.Controls`. Import these modules explicitly; `Blockstream.Green` does not re-export them. It exposes the design system semantic colors and text styles. Existing components still contain older styling; use the tokens for new UI and future migrations.

### Components

Place new design system components in `modules/controls/qml/` and prefix their filenames and QML type names with `Ui`, for example `UiButton.qml`, `UiTextField.qml`, `UiAlert.qml`, and `UiCard.qml`. They belong to the `Blockstream.Controls` module; register them in its `QML_FILES` in `modules/controls/qml/CMakeLists.txt`. Theme files belong to `Blockstream.Theme` in `modules/theme/`. Neither module imports `Blockstream.Green`, and `Blockstream.Theme` does not import `Blockstream.Controls`. Use `Theme.colors` and `Theme.typography` for their styling.

#### Input, progress, scrolling, and tooltip controls

`UiTextArea` retains native multiline editing, selection, and `readOnly`. It wraps
text and grows with content; constrain it with a scrolling container where needed.
Use `disabled` to block editing and `errorMessage` for caller-owned validation.
Its error panel follows UiTextField, including the delayed reveal and accessible
description. Neither control clears errors when text changes.
Pass a caller-defined `Row` or other `Item` through `UiTextArea.actions` for the
bottom-left slot. The caller owns its buttons, styling, and handlers; the text
area only hosts and positions the item. Set `clearable: false` to disable the bottom-right clear
button. The minimum total height is 128px, leaving room for about three text
lines above the standard action row. The gallery can hide its custom actions
independently of Clear. The Clear
button is hidden for empty, disabled, or read-only input and emits `cleared`
after restoring editor focus. If a focused Clear button is hidden by a text reset
or a switch to read-only, focus returns to the enabled editor. Disabling the
control does not restore editor focus. Clearable defaults to true. The action row reserves
space below the text and above validation, including when the clear button is
hidden. Inside a ScrollView or with `TextArea.flickable`, actions, Clear, and
validation stay at the bottom of the viewport while the text scrolls. A growing
text area within a scrollable page still scrolls as part of that page.
Tab moves focus from the editor to the next item in Qt's native focus
chain without inserting a tab character. Focus navigation respects platform
preferences; the component does not force action buttons into the tab chain
when macOS is configured to tab only to text controls.

`UiComboBox` retains `model`, `textRole`, `valueRole`, `currentIndex`,
`currentValue`, and `activated`. It is a non-editable single selector with a
scrollable popup. Use native role-based models and handle `onActivated` to write
user selections back to caller state. Editable/searchable combinations are not
supported by its presentation.

`UiSlider` retains native `from`, `to`, `value`, `stepSize`, `snapMode`,
`orientation`, and `moved`. Bind `value` to caller state and update that state in
`onMoved`. Use `disabled` for availability. `UiProgressBar` supports measured and
indeterminate linear progress. `UiCircularProgress` uses the native ProgressBar
range/value API for measured progress, with `diameter` (24) and `strokeWidth` (2).
Use `UiSpinner` for ordinary loading. All expose `colors` for gallery previews.

Attach `UiScrollBar` and `UiScrollIndicator` through the standard Qt attached
properties; their range and activity follow the Flickable. The scrollbar is
interactive and supports native policy settings. It defaults to `Qt.NoFocus`,
preserving editor focus during pointer scrolling
and staying outside the tab chain. Callers may opt into `Qt.TabFocus` for arrow-key
scrolling along its orientation while `interactive` is enabled.
Instantiate `UiToolTip` inside its target and bind `visible` to the target's hover state; native `delay`,
`timeout`, `show`, and `hide` remain available. Constrain width for wrapped hints.


### Colors

Choose the semantic role that describes the element, rather than matching a hex value or palette shade. Token paths become camel case names in QML: `text/primary` becomes `Theme.colors.textPrimary`, and `feedback/negative/on-fill` becomes `Theme.colors.feedbackNegativeOnFill`. Available groups are text, action, border, feedback, icon, overlay, and surface.

```qml
import Blockstream.Theme
import QtQuick
import QtQuick.Controls

Label {
    color: Theme.colors.textPrimary
}
```

`modules/theme/qml/Colors.qml` defines the required semantic color properties. `LightColors.qml` and `DarkColors.qml` provide their values. `Theme.dark` selects the active palette through `Theme.colors` and defaults to dark. Use `Theme.colors` in product QML. The debug gallery selects `Theme.lightColors` or `Theme.darkColors` independently, so its preview switch does not change the application palette.

### Typography

Each text style has a `Theme.typography` object. Names follow the style path in camel case: `body/l` is `bodyL`, `label/m-medium` is `labelMMedium`, and `title/xxl-bold` is `titleXxlBold`. Styles without a weight suffix use their base name in QML. Each style exposes `.font` and `.lineHeight`. The font includes family, logical pixel size, weight, letter spacing, and capitalization.

```qml
import Blockstream.Controls
import Blockstream.Theme
import QtQuick
import QtQuick.Controls

UiLabel {
    text: qsTrId("id_settings")
    color: Theme.colors.textPrimary
    typography: Theme.typography.bodyM
}
```

`UiLabel` binds both the font and fixed line height from one style. Qt keeps line height separate from `font`, so for a plain `Text` or `Label`, bind both `.font` and `.lineHeight` and set `lineHeightMode: Text.FixedHeight`. For controls that only expose `font`, bind `.font` and let the control manage its own text layout. A fixed line height can clip glyphs, so inspect new multiline uses in the target platform and language.

Inter covers body, label, title, overline, and display styles. Code styles use Roboto Mono. The app registers the required TTF files at startup.

### Updating token definitions

Add each semantic color property to `modules/theme/qml/Colors.qml` and its values to both `LightColors.qml` and `DarkColors.qml`, keeping each token's path comment. Update text styles in `modules/theme/qml/Typography.qml`. Update font assets and registration if families or weights change.

### UI icons

Use `UiIcon` with a name from `Theme.icons`:

```qml
import Blockstream.Controls
import Blockstream.Theme

UiIcon {
    name: Theme.icons.plusBold
    color: Theme.colors.iconBase
    size: 24
}
```

Defaults are an empty name, 24 logical pixels, and `Theme.colors.textPrimary`.
Empty or unknown names hide the icon. Width, height, and layout properties can
override its size. With the default `colorize: true`, `color` supplies the tint
and its alpha controls transparency. Use `colorize: false` for assets such as
`Theme.icons.jade` and `Theme.icons.ledger`: this bypasses the colorization layer
and ignores `color`, including its alpha, preserving the SVG's original colors.
Set the item's `opacity` to fade an original-color icon. Icons are decorative and
non-interactive.

For buttons, use `iconName` and `trailingIconName`:

```qml
UiButton {
    text: qsTrId('id_continue')
    iconName: Theme.icons.check
    trailingIconName: Theme.icons.arrowRight
}
```

`Theme.icons` exposes typed readonly string properties from `Icons.qml`, supporting
editor completion. SVG filenames generate these properties; the gallery derives
its list from them. Theme caches valid names in `iconNames` for UiIcon lookups.
Theme also supplies the SVG resources; Controls supplies the UiIcon renderer.
See [adding icons](repository.md#uiicon-assets) for importing
and regeneration instructions.

### Debug gallery

In non-production builds, launch with `--debug` and select **Design system** in the sidebar to inspect colors, typography, and component examples. The gallery is the `Blockstream.DesignSystem` module in `modules/design-system/`; it is not built when `GREEN_ENV` is `Production`, and the sidebar entry stays hidden even with `--debug`. AppPage loads the gallery by its resource URL so production does not depend on its QML types. Like the other design system modules, it does not import `Blockstream.Green`. The preview palette switch changes the whole gallery, including its background and controls, without changing the rest of the app. The Typography tab and UiLabel section each have a sample text field; each field updates only its own previews.

Keep the grouped token names and design IDs in `modules/design-system/qml/catalog.js` in sync when adding or renaming tokens. Add future component examples to the Components tab in `modules/design-system/qml/DesignSystemPage.qml`; reusable components belong in `modules/controls/qml/`.

The tabs are Colors, Typography, Icons, and Components. The Icons tab lists brand
icons first with `colorize: false`, then theme-colored UI icons, using the same
four-column rows. Search covers both subsections. Tertiary Copy buttons copy
`Theme.icons` expressions and briefly read Copied after use. Brand rows follow the preview palette, with a small dark logo tile in both
palettes so the original white logo details stay visible.
The Components tab has a case-insensitive search by component name, including
partial matches such as `button` or `area`. Clearing search restores all sections.
It includes card, menu, and popup examples; use them to inspect
hover, keyboard focus, disabled states, counts, long labels, scrolling, and dismissal.

`UiButton` provides `variant` (`Primary`, `Secondary`, `Tertiary`, `Negative`, `PrimaryInverted`, `SecondaryInverted`) and `size` (`Large`, `Medium`, `Small`, `ExtraSmall`) enums; defaults are `UiButton.Primary` and `UiButton.Medium` (48px). Use `iconName: Theme.icons.check` for a leading icon and `trailingIconName: Theme.icons.copy` for a trailing icon. Both render through UiIcon and follow the button foreground color; empty or unknown names are hidden. `busy` replaces content with a spinner and preserves dimensions and normal variant colors. Use `disabled` (default `false`) for caller-controlled availability. Leave inherited `enabled` untouched so the component's `enabled: !disabled && !busy` binding blocks activation during loading. QML still permits overriding `enabled`, which replaces this binding. Qt handles pointer input, keyboard activation, focus, and shortcuts.

```qml
UiButton {
    Layout.fillWidth: true
    variant: UiButton.Primary
    size: UiButton.Medium
    text: qsTrId('id_continue')
    busy: controller.loading
    disabled: !controller.canSubmit
    onClicked: controller.submit()
}
```

The Components tab includes a UiButton playground and live examples of every variant and size. Hover/pressed/focus use real input; there is no forced state property. Use `colors` only for a local preview override; product buttons default to `Theme.colors`.

`UiIconButton` is a square UiButton with one centered `iconName`. Set `text` to
its accessible action name; labels and trailing icons are not rendered. It defaults
to UiButton.Tertiary (ghost) and Medium, and also supports Primary, Secondary and
Neutral. Use `variant: UiButton.Neutral` for Close actions: `iconSubtle` at rest,
`iconBase` on hover/press, and a surface using `iconBase` at 10% opacity on hover/press.
Neutral buttons retain UiButton's existing 8px corner radius; the inset surface
uses a 4px radius during keyboard focus.
Disabled icons use `iconDisabled` without a fill; keyboard focus keeps the inset
ring and subtle icon. The loading spinner keeps the neutral foreground.
Large/Medium/Small/ExtraSmall measure 56/40/36/28px with 24/24/20/16px icons.
States, colors, and loading behavior are inherited from UiButton.

```qml
UiIconButton {
    text: qsTrId('id_copy_address')
    iconName: Theme.icons.copy
    variant: UiButton.Secondary
    size: UiButton.Small
    onClicked: { /* perform the action */ }
}
```

The Components tab previews variants, sizes, disabled, and loading in both themes.

`UiRadio` is a Basic `RadioButton` that draws the 20px Figma indicator followed by its `text` label (`body/m`, 8px spacing). The label is also the accessible name, and hovering or clicking it acts on the radio. Set `wrapMode` and `elide` when the control width is constrained (for example with `Layout.fillWidth`). It keeps the native radio behavior: sibling auto-exclusivity or `ButtonGroup.group`, `checked` bindings with `onToggled`, Tab focus, and Space activation. Use `disabled` (default `false`) like UiButton; disabled radios do not activate. The keyboard focus ring is drawn outside the indicator, so focus does not change the control size. `colors` is only for gallery preview overrides.

```qml
ButtonGroup {
    id: fee_group
}
UiRadio {
    ButtonGroup.group: fee_group
    text: qsTrId('id_fast')
    checked: controller.feeRate === 'fast'
    onToggled: controller.feeRate = 'fast'
}
```

`UiCheckbox` is a Basic `CheckBox` that draws the 20px Figma indicator for unchecked, checked, and indeterminate states, followed by its `text` label (`body/m`, 8px spacing). The label is also the accessible name, and hovering or clicking it acts on the checkbox. Set `wrapMode` and `elide` when the control width is constrained (for example with `Layout.fillWidth`). It keeps the native checkbox behavior: `checked` or `checkState` bindings with `onToggled`, Tab focus, Space activation, `tristate`, `nextCheckState`, and `ButtonGroup` with `exclusive: false` for select-all parents. As in Qt, an indeterminate checkbox reports `checked: false` and exposes the mixed state through `Accessible.checkStateMixed`. Use `disabled` (default `false`) like UiButton; disabled checkboxes do not activate. The keyboard focus ring is drawn outside the indicator, so focus does not change the control size. `colors` is only for gallery preview overrides.

```qml
UiCheckbox {
    id: remember_checkbox
    text: qsTrId('id_remember_me')
    checked: controller.remember
    onToggled: controller.remember = remember_checkbox.checked
}
```

`UiToggle` is a Basic `Switch` that draws its `text` label (`body/m`) followed by the 48×28px Figma on/off control, 8px apart. The control stays right-aligned, so a toggle with `Layout.fillWidth: true` forms a settings row. The label is also the accessible name, and hovering or clicking it acts on the toggle. Set `wrapMode` and `elide` when the control width is constrained. It exposes `Accessible.Switch` with its on/off state and keeps the native switch behavior: `checked` bindings with `onToggled`, Tab focus, Space activation, dragging, and the animated knob. Use `disabled` (default `false`) like UiButton; disabled toggles do not activate. The keyboard focus ring is drawn inside the control and the track shrinks, so focus does not change the control size. `colors` is only for gallery preview overrides.

```qml
UiToggle {
    id: remember_toggle
    Layout.fillWidth: true
    text: qsTrId('id_remember_me')
    checked: controller.remember
    onToggled: controller.remember = remember_toggle.checked
}
```

`UiDivider` draws a 1px separator. Set `orientation` to `Qt.Horizontal` (default) or `Qt.Vertical`, and `weight` to `UiDivider.Subtle` (default, `border/subtle`) or `UiDivider.Bold` (`border/bold`). Inside layouts, it fills the width when horizontal or the height when vertical, and its thickness stays at 1px. Outside layouts, set the length with `width`, `height`, or anchors. It is non-interactive, never takes keyboard focus, and exposes `Accessible.Separator`. `colors` is only for gallery preview overrides.

```qml
UiDivider {}
UiDivider { orientation: Qt.Vertical; weight: UiDivider.Bold }
```

`UiLink` is an underlined text link with a trailing 16px icon. Set `text` (also the accessible name), `url`, `size` (`UiLink.Large` by default, or `UiLink.Medium`), and `iconName` (`Theme.icons.arrowSquareOut` by default; empty hides it). A click, Space, Return, or Enter emits `linkActivated(url)` and opens the URL like `LinkLabel`. Disabled links and links without a `url` do not activate.

```qml
UiLink {
    size: UiLink.Medium
    text: qsTrId('id_learn_more')
    url: 'https://help.blockstream.com/hc/en-us/articles/900001392563-What-is-a-recovery-phrase'
}
```

`UiAlertBanner` is a `Page`-based status banner (same header/content/footer split as `StackViewPage` / `AlertView`) for Negative, Warning, and Info variants. `header` is null; the content row holds the 24px status icon, optional `title` (`label/l-semibold`, `textPrimary`), wrapping `description` (`body/m`, `textSubtle`), and optional dismissal through `UiIconButton`. Put footer actions as children (a `UiButton`, `UiLink`, or a `Row` of controls); they align with the text column (not under the icon/dismiss). The banner does not hardcode button props. Height grows with content; long text wraps instead of clipping. Callers handle child `clicked` / `linkActivated` and `dismissed` for navigation, persistence, and visibility. Use `disabled` to block dismissal. Override `iconName` when the default semantic icon is not right. `colors` is only for gallery preview overrides.

```qml
UiAlertBanner {
    Layout.fillWidth: true
    variant: UiAlertBanner.Warning
    title: qsTrId('id_back_up_recovery_phrase')
    description: qsTrId('id_learn_more')
    dismissible: true
    onDismissed: banner.visible = false
    Row {
        spacing: 8
        UiButton {
            size: UiButton.ExtraSmall
            variant: UiButton.PrimaryInverted
            text: qsTrId('id_continue')
            onClicked: stack_view.push(backup_page)
        }
        UiButton {
            size: UiButton.ExtraSmall
            variant: UiButton.SecondaryInverted
            text: qsTrId('id_cancel')
        }
    }
}
```

`UiTabs` is a Basic `TabBar` and `UiTab` is a Basic `TabButton` for the Figma tab item (60px tall, 24px horizontal padding). The selected tab uses `textPrimary` with a 2px `borderBrand` underline; inactive tabs use `textSubtle` and lighten to `textPrimary` on hover. Use `disabled` like UiButton so a tab cannot activate or become selected through pointer or keyboard input. The keyboard focus ring is drawn outside the tab, so focus does not change its size. Set `wrapMode` and `elide` when a tab width is constrained. `UiTabs` exposes native `currentIndex` / `currentItem` selection; keep page content and routing in a caller-owned `StackLayout` or similar. On `UiTab`, `colors` is only for gallery preview overrides.

```qml
UiTabs {
    id: account_tabs
    Layout.fillWidth: true
    UiTab { text: qsTrId('id_transactions') }
    UiTab { text: qsTrId('id_coins') }
    UiTab { text: qsTrId('id_addresses') }
}
StackLayout {
    currentIndex: account_tabs.currentIndex
    // caller-owned pages...
}
```

`UiSpinner` wraps the Material `BusyIndicator` used by UiButton. Set `size` in pixels (default 20), `color` (default `Theme.colors.textPrimary`), and `running` to show and animate it. Animation is handled by Qt.

`UiTextField` extends Basic `TextField` with theme styling, native editing and validators. `size` defaults to `UiTextField.Large` (60px); use `UiTextField.Medium` (44px) or `UiTextField.Small` (36px) for compact inputs. Set `disabled` (default `false`) without overriding `enabled`; content is retained. Native `readOnly` permits selection and copying. Both hide clear. `errorMessage` controls the error border, wrapping panel, and accessible description. Callers own errors; validation and clearing never change them. The panel opens after 120ms and smoothly expands or collapses below the fixed input shell, including while disabled. `clearable` defaults to `true`. Filled editable fields show a keyboard-accessible clear button that returns focus to the editor. Clearing emits `textChanged` and `cleared()`, but not `textEdited`; handle `cleared` when syncing edits to caller state.

`UiTextField.iconName` adds a decorative leading icon. `leadingItem` replaces
that icon; `trailingItem` supplies a caller-owned action beside the built-in clear
button. Supply items with explicit or implicit dimensions and native keyboard
focus behavior. Tab visits the editor, visible and enabled focusable leading and
trailing items, then clear; Backtab reverses this order and exits the field.
Wallet operations belong to the caller. Set `Accessible.id` on
the field to derive `<id>_clear_btn`; assign semantic IDs to supplied actions, for
example `<id>_copy_btn`. An empty root ID or `clearable: false` leaves the built-in action unidentified.
`UiAlertBanner` similarly derives `<id>_dismiss_btn` from its root `Accessible.id`.
These bindings follow subsequent root ID changes.

`invalid` marks a field invalid without adding a message panel; retained application
fields use it for legacy `error` values whose message is rendered by the caller.
`errorMessage` still supplies the optional built-in panel. UiTextArea supports the
same `invalid` contract. UiTextField exposes `borderColor` and `borderWidth` for
retained caller-owned status outlines; ordinary fields keep their themed defaults.

`fieldHeight` can be overridden for composed inputs such as AmountField; the
background, slots and validation panel follow that height. Ordinary fields should
keep the size-derived default.

Replacing or clearing a text-field action slot detaches its old item from the
visual tree without destroying it. Callers can assign that item to a slot again.

```qml
UiTextField {
    placeholderText: qsTrId('id_name')
    errorMessage: controller.errorMessage
    disabled: controller.loading
    Accessible.name: qsTrId('id_name')
    onTextEdited: controller.name = text
    onCleared: controller.name = ''
}
```

## Shared cards, menus, and popups

Use `UiCard` for a static surface with caller-owned `contentItem`. It defaults to
24px padding, a subtle border, and a 4px radius. Use `UiCardButton` when the whole
card is one action; supply its `text` for the accessible name, its `contentItem`
for the visible content, and handle `onClicked`. Use `disabled` for availability
rather than replacing its `enabled` binding. It supports hover, press, Tab focus,
and Space activation; its focus border does not alter padding. Supply content
colors from the theme, including disabled colors where appropriate. Both controls
accept `colors` for gallery previews. Keep wallet-specific row content in the
product QML files rather than adding it to these shared controls.

`UiMenuItem` renders `checkable` / `checked` with a trailing check. Use native
`ActionGroup` exclusivity for sorting and independent checkable actions for
filters. Hover/highlight remains separate from checked state.

`UiMenu` is the shared action menu. Add `UiMenuItem` children and
`UiMenuSeparator` between groups. Items accept `text`, `iconName`, `count`
(default 0), and inherited `enabled`. Pass a translated label and numeric count
separately; parentheses in `text` are literal. Counts greater than zero appear in
a badge and are included in the accessible name. Handle actions in `onTriggered`;
Qt closes the menu when an action triggers. Disabled items cannot activate.
Labels stay on one line and elide when necessary. The menu sizes to its items
between 200px and 360px wide and caps its height at 300px, with scrolling for
longer content. For generated items, use `Instantiator` with `insertItem` and
`removeItem`, as in `PopupsGallery.qml`; do not put a `Repeater` directly in the menu.

```qml
UiButton {
    text: qsTrId('id_more')
    onClicked: options_menu.open()
    UiMenu {
        id: options_menu
        accessibleId: 'example_options_menu'
        y: parent.height + 8
        UiMenuItem {
            text: qsTrId('id_view_archived_accounts')
            count: 2 // Bind to the actual count at the call site.
            iconName: Theme.icons.archive
            onTriggered: console.log('Open archived accounts')
        }
    }
}
```

Use `UiPopup` for arbitrary interactive content rather than an action list. It
provides 16px padding, focus handling, and a themed `UiPopupSurface`; callers own
content, actions, dimensions, and placement. `UiPopupSurface` is the common visual
background, not an interactive popup on its own. Its pointer coordinates are
normalized (`pointerX: 0.5`, `pointerY: 0`); callers position the popup and its
pointer so neither extends beyond the available viewport. `UiPopup` exposes
`pointerX`; `UiMenu` exposes both `pointerX` and `pointerY`.

Both `UiMenu` and `UiPopup` are modal without dimming. Escape or a press outside
closes them. The outside press is consumed, including a press on the trigger,
so a single click dismisses without reopening. Retain this behavior when adding
callers; do not disable a trigger merely because its popup is visible.

### Dialog and drawer shells

`UiDialog` and `UiDrawer` are presentation shells based on the legacy
`AbstractDialog` and `AbstractDrawer`, using the Figma modal/drawer foundations:
32px padding, `surfaceOverlay`, and modal background blur. The current
surfaces have no border, shadow, or additional scrim fill. They expose `colors` for preview palettes and `accessibleId`
for the visual content root. UiDialog provides a title and Close
header; UiDrawer leaves its header to the caller. Callers own body content, hints,
actions and scrolling; legacy wrappers remain until individual flows migrate.

`UiDialog` defaults to 400px wide, centered in the window overlay, with a 12px
radius. It has 24px external margins and shrinks to the available
window width. Override `implicitWidth` for wider bodies (for example 480px or
560px), or `width` for a custom sizing policy. Content determines height; provide
a scrollable body for content taller than the window. The default header uses
`title` and a Close button calling `reject()`. Close is shown even without a
title. `dismissible` defaults to true; set it to false to hide and disable Close
and block Escape/outside-click dismissal through the default `closePolicy`
binding. Leave that binding intact when using `dismissible` to control all three.
An explicit `Popup.NoAutoClose` policy also hides and disables Close. When Close
is hidden and the title is empty, the default header is hidden. Changes take
effect while the dialog is open. Caller-owned actions may still call `accept()`,
`reject()`, or `close()`. The default header shares the
dialog's 32px outer inset, with only `spacing` between the header and body. The
Close button derives `<accessibleId>_close_btn`; empty IDs stay empty. Override
`header` or set `header: null` for a custom presentation. `footer` is null by
default, so `standardButtons` does not create an action row; supply your own
actions and call `accept()` / `reject()` when appropriate. Native section
spacing is 20px; caller-owned layouts should also use 20px between body sections.

`UiDrawer` defaults to the right edge and full overlay height, with a plain
rectangular surface. Set `edge: Qt.LeftEdge` for a wallet picker. Like the
reference wrapper, it exposes `minimumContentWidth` (450px) and
`preferredContentWidth` (0px), measured before padding. The default content width
plus 32px padding on each side produces 514px overall when the window has room.
The content width follows the larger value, capped by the window's available
width; a `SmoothedAnimation` handles width changes. Provide a `Page` with
`padding: 0`, `spacing: 20`, a scrollable body, and an optional footer when that
layout is needed. Closed drawers do not open through edge dragging; opening is
caller-controlled, while an open drawer retains native drag-to-dismiss behavior.

Both shells use Escape/outside-press dismissal and consume the outside press.
Their surfaces use the supplied `colors`; the shared controls depend only on
Theme and Qt, not on application wallet types. The gallery demonstrates a
caller-owned dialog action layout and a drawer with a pinned bottom action,
short/long content, and both side edges.

### Popup test IDs

Set `accessibleId` on `UiMenu`, `UiPopup`, `UiDialog`, and `UiDrawer`, rather than
attaching `Accessible.id` to those popup objects. The components bind it to `contentItem.Accessible.id`,
which is a visual item. Identified content roots also receive an accessible role
that remains exposed in the native tree: Dialog for dialogs, Grouping for popups
and drawers, and PopupMenu for menus. On macOS all four use Grouping because
Qt flattens PopupMenu nodes and reserves window roles for native windows.
Clearing the ID restores the content's original role. The shared
`PopupAccessibility` helper resolves binding targets during component completion,
after caller-supplied initial content is assigned.
The bindings track changes to `accessibleId` and replacement of `contentItem`, including
caller-owned content. Assign the root ID through `accessibleId` only; give
individual actions their own `Accessible.id` values.

```qml
UiPopup {
    accessibleId: 'example_details_popup'
    contentItem: UiLabel {
        text: qsTrId('id_details')
        typography: Theme.typography.bodyM
        color: Theme.colors.textPrimary
    }
}
```

This contract covers these four shared controls. Migration of legacy
dialog/drawer/scanner wrappers, automatic back-button IDs, and fixed-versus-prefixed
IDs in other reusable components still require the coordinated foundations work. Do not invent a
second naming policy in a flow migration.

## Custom background pattern

```qml
background: Rectangle {
    color: parent.pressed ? Theme.colors.surfaceSunken : Theme.colors.surfaceRaised
    radius: 5
    border.width: 1
    border.color: parent.selected ? Theme.colors.borderBrand : Theme.colors.borderSubtle
}
```

## Focus and hover

```qml
// Visual focus indicator
background: Item {
    Rectangle {
        anchors.fill: parent
        border.color: Theme.colors.borderBrand
        border.width: 2
        color: 'transparent'
        radius: 8
        visible: self.visualFocus
    }
    Rectangle {
        anchors.fill: parent
        anchors.margins: self.visualFocus ? 4 : 0
        color: self.hovered ? Theme.colors.surfaceRaised : Theme.colors.surfaceBase
        radius: self.visualFocus ? 4 : 8
    }
}

// Hover cursor
HoverHandler {
    cursorShape: Qt.PointingHandCursor
}
```

## Timer for debouncing

```qml
Timer {
    id: quote_fetch_timer
    interval: 500
    onTriggered: {
        // Debounced action
    }
}

TextField {
    onTextChanged: quote_fetch_timer.restart()
}
```

## Connections for external signals

```qml
Connections {
    target: SomeService
    function onSomeSignal() {
        // Handle signal
    }
}
```

## StackView navigation

`StackViewPage` exposes `pushPage(...)` / `popPage(...)` / `replacePage(...)`
wrappers around `self.StackView.view.push/pop/replace`. Prefer these over
reaching into `self.StackView.view` directly.

```qml
// Pushing pages
self.pushPage(component_id, {
    context: self.context,
    account: self.account
})

// Popping
self.popPage()

// With signal callback
onSelected: (account, asset) => {
    self.popPage()
    controller.account = account
}
```

When creating objects dynamically, pass all required context at creation time and let the created item own its lifecycle if it is a dialog or drawer:

```qml
const drawer = request_drawer.createObject(self, {
    context: self.context,
    session: self.session
})
drawer.open()
```

## Component definitions (at end of file)

```qml
Component {
    id: account_selector_page
    AccountSelectorPage {
        context: self.context
        onAccountClicked: (account) => {
            self.account = account
            self.popPage()
        }
    }
}
```

## Page structure (StackViewPage)

```qml
StackViewPage {
    required property Context context

    id: self
    title: 'Page Title'

    rightItem: CloseButton {
        onClicked: self.closeClicked()
    }

    contentItem: VFlickable {
        alignment: Qt.AlignTop
        // Content here
    }

    footerItem: ColumnLayout {
        PrimaryButton {
            Layout.fillWidth: true
            text: 'Action'
            onClicked: { }
        }
    }

    // Component definitions at the end
    Component {
        id: next_page
        NextPage { }
    }
}
```

## Button states

```qml
PrimaryButton {
    Layout.fillWidth: true
    enabled: amount_input.text.length > 0 &&
             parseFloat(amount_input.text) > 0 &&
             !Service.loading &&
             Service.error.length === 0
    busy: Service.loading
    text: Service.loading ? 'Loading...' : 'Submit'
    onClicked: { }
}
```

## User-facing text

Use `qsTrId(...)` for user-facing strings when an id already exists or when adding text to translated flows. Literal strings are acceptable for debug/internal UI, network names, protocol names, or files that already deliberately use literals. Do not replace existing translation ids with hardcoded English.

On macOS, UiAlertBanner uses accessible Grouping because Cocoa omits the
AlertMessage container and its runtime ID. Its name, description, and dismissal
action remain intact.
