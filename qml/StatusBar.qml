import QtQuick 2.12
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.12

GPane {
    id: self
    topPadding: 8
    bottomPadding: 8
    leftPadding: 24
    rightPadding: 24
    focusPolicy: Qt.ClickFocus
    background: Rectangle {
        color: constants.c800
    }
}
