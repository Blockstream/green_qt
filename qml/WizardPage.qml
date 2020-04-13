import QtQuick 2.13
import QtQuick.Controls 2.5

Page {
    background: Item {}

    property list<Action> actions
    property bool next: true
    property Action accept: Action {}
    property Action cancel: Action {}
    property Action reject: Action {}
}
