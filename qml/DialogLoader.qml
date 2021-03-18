import QtQuick 2.13
import QtQuick.Controls 2.13

QtObject {
    property bool active: false
    required property Component dialog
    property Dialog __instance: null
    id: self
    onActiveChanged: {
        if (active) {
            const instance = self.__instance = dialog.createObject(window)
            instance.closed.connect(function () {
                instance.destroy()
            })
            instance.open()
        } else if (self.__instance) {
            self.__instance.close()
            self.__instance = null
        }
    }
}
