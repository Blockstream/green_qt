import Blockstream.Theme
import QtQuick
import QtQuick.Controls

Label {
    required property TypographyStyle typography

    id: self
    font: self.typography.font
    lineHeightMode: Text.FixedHeight
    lineHeight: self.typography.lineHeight
}
