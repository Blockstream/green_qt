pragma Singleton

import QtQuick

QtObject {
    property bool dark: true

    readonly property DarkColors darkColors: DarkColors {}
    readonly property LightColors lightColors: LightColors {}
    readonly property Colors colors: dark ? darkColors : lightColors

    readonly property Icons icons: Icons {}
    // Cache valid names so each UiIcon lookup avoids scanning all icons.
    readonly property var iconNames: new Set(Object.keys(self.icons)
        .filter(key => key !== 'objectName' && typeof self.icons[key] === 'string')
        .map(key => self.icons[key]))

    readonly property Typography typography: Typography {}

    id: self
}
