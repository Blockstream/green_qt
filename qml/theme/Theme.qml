pragma Singleton

import QtQuick

QtObject {
    property bool dark: true

    readonly property DarkColors darkColors: DarkColors {}
    readonly property LightColors lightColors: LightColors {}
    readonly property Colors colors: dark ? darkColors : lightColors
    readonly property Typography typography: Typography {}
}
