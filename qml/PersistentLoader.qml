import QtQuick 2.12

Loader {
    property bool load: false
    property bool initialized: false
    active: initialized || load
    asynchronous: true
    onActiveChanged: if (active) Qt.callLater(() => { initialized = true })
}
