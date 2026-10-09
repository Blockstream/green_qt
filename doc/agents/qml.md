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

Place new design system components in `qml/controls/` and prefix their filenames and QML type names with `Ui`, for example `UiButton.qml`, `UiTextField.qml`, `UiAlert.qml`, and `UiCard.qml`. They belong to the `Blockstream.Controls` module; register them in its `QML_FILES` in `qml/controls/CMakeLists.txt`. Theme files belong to `Blockstream.Theme` in `qml/theme/`. Neither module imports `Blockstream.Green`, and `Blockstream.Theme` does not import `Blockstream.Controls`. Use `Theme.colors` and `Theme.typography` for their styling.

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

`qml/theme/Colors.qml` defines the required semantic color properties. `LightColors.qml` and `DarkColors.qml` provide their values. `Theme.dark` selects the active palette through `Theme.colors` and defaults to dark. Use `Theme.colors` in product QML. The debug gallery selects `Theme.lightColors` or `Theme.darkColors` independently, so its preview switch does not change the application palette.

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

Add each semantic color property to `qml/theme/Colors.qml` and its values to both `LightColors.qml` and `DarkColors.qml`, keeping each token's path comment. Update text styles in `qml/theme/Typography.qml`. Update font assets and registration if families or weights change.

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
override its size. Color alpha controls transparency. Icons are decorative and
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

In non-production builds, launch with `--debug` and select **Design system** in the sidebar to inspect colors, typography, and component examples. The gallery is the `Blockstream.DesignSystem` module in `qml/design-system/`; it is not built when `GREEN_ENV` is `Production`, and the sidebar entry stays hidden even with `--debug`. AppPage loads the gallery by its resource URL so production does not depend on its QML types. Like the other design system modules, it does not import `Blockstream.Green`. The preview palette switch changes the whole gallery, including its background and controls, without changing the rest of the app. The Typography tab and UiLabel section each have a sample text field; each field updates only its own previews.

Keep the grouped token names and design IDs in `qml/design-system/catalog.js` in sync when adding or renaming tokens. Add future component examples to the Components tab in `qml/design-system/DesignSystemPage.qml`; reusable components belong in `qml/controls/`.

The UiIcon section lists icons in four compact columns, with search and tertiary
Copy buttons for `Theme.icons` expressions. Buttons briefly read Copied after use.

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
to UiButton.Tertiary (ghost) and Medium, and also supports Primary and Secondary.
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

`UiSpinner` wraps the Material `BusyIndicator` used by UiButton. Set `size` in pixels (default 20), `color` (default `Theme.colors.textPrimary`), and `running` to show and animate it. Animation is handled by Qt.

`UiTextField` extends Basic `TextField` with theme styling, native editing and validators. `size` defaults to `UiTextField.Large` (60px); use `UiTextField.Medium` (44px) or `UiTextField.Small` (36px) for compact inputs. Set `disabled` (default `false`) without overriding `enabled`; content is retained. Native `readOnly` permits selection and copying. Both hide clear. `errorMessage` controls the error border, wrapping panel, and accessible description. Callers own errors; validation and clearing never change them. The panel opens after 120ms and smoothly expands or collapses below the fixed input shell, including while disabled. `clearable` defaults to `true`. Filled editable fields show a keyboard-accessible clear button that returns focus to the editor. Clearing emits `textChanged` and `cleared()`, but not `textEdited`; handle `cleared` when syncing edits to caller state.

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
