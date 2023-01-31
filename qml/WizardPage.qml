import QtQuick
import QtQuick.Controls

Page {
    background: null

    property list<Action> actions
    property bool next: true
    property Action accept: Action {}
    property Action cancel: Action {}
    property Action reject: Action {}
}
