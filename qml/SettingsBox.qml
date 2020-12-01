import QtQuick 2.13
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.13

Page {
    header: SectionLabel {
        text: title
        bottomPadding: 8
    }
    background: Item {
        Rectangle {
            y: parent.height
            width: parent.width
            color: 'gray'
            opacity: 0.2
            height: 1
        }
    }
    Layout.fillWidth: true
    Layout.topMargin: 16
}
