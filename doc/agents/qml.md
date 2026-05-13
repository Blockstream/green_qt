# QML conventions

These notes apply to QML under `qml/`. They are part of the repository agent instructions; start from [AGENTS.md](../../AGENTS.md).

## Import order

```qml
import Blockstream.Green       // Project imports first
import Blockstream.Green.Core
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

## Styling constants

```qml
// Colors (always hex strings)
color: '#FFFFFF'          // White text
color: '#A0A0A0'          // Muted text
color: '#6F6F6F'          // Subtle text
color: '#00BCFF'          // Accent cyan
color: '#FF6B6B'          // Error red
color: '#181818'          // Dark background
color: '#222226'          // Card background
color: '#262626'          // Border color
color: '#313131'          // Lighter border

// Font sizes
font.pixelSize: 28        // Large headers
font.pixelSize: 16        // Body text
font.pixelSize: 14        // Labels
font.pixelSize: 12        // Small/caption

// Font weights (numeric)
font.weight: 700          // Bold
font.weight: 600          // Semi-bold
font.weight: 500          // Medium
font.weight: 400          // Regular

// Padding (explicit, not defaults)
padding: 20
leftPadding: 12
rightPadding: 12
topPadding: 10
bottomPadding: 10

// Radius
radius: 5                 // Standard cards
radius: 8                 // Buttons
radius: 4                 // Small elements
```

## Custom background pattern

```qml
background: Rectangle {
    color: parent.pressed ? '#1a1a1a' : '#181818'
    radius: 5
    border.width: 1
    border.color: parent.selected ? '#4FD1FF' : '#262626'
}
```

## Focus and hover

```qml
// Visual focus indicator
background: Item {
    Rectangle {
        anchors.fill: parent
        border.color: '#00BCFF'
        border.width: 2
        color: 'transparent'
        radius: 8
        visible: self.visualFocus
    }
    Rectangle {
        anchors.fill: parent
        anchors.margins: self.visualFocus ? 4 : 0
        color: Qt.lighter('#181818', self.hovered ? 1.2 : 1)
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

```qml
// Pushing pages
self.StackView.view.push(component_id, {
    context: self.context,
    account: self.account
})

// Popping
self.StackView.view.pop()

// With signal callback
onSelected: (account, asset) => {
    self.StackView.view.pop()
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
            self.StackView.view.pop()
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
