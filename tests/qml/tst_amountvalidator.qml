import QtQuick
import QtTest

GreenTestCase {
    name: "tst_amountvalidator"

    function test_acceptableInput_data() {
        return [
            { tag: "integer", text: "123", acceptable: true },
            { tag: "dot decimal", text: "123.45", acceptable: true },
            { tag: "comma decimal", text: "123,45", acceptable: true },
            { tag: "grouped with space", text: "12 345", acceptable: true },
            { tag: "leading separator", text: ".5", acceptable: true },
            { tag: "trailing separator", text: "1.", acceptable: true },
            { tag: "trailing space", text: "123 ", acceptable: true },
            { tag: "letters", text: "abc", acceptable: false },
            { tag: "trailing letter", text: "12a", acceptable: false },
            { tag: "leading letter", text: "a12", acceptable: false },
            { tag: "two separators", text: "1.2.3", acceptable: false },
            { tag: "negative", text: "-5", acceptable: false },
            { tag: "exponent", text: "1e5", acceptable: false },
            { tag: "digits after trailing space", text: "1.5 0", acceptable: false }
        ]
    }

    function test_acceptableInput(row) {
        const component = Qt.createComponent("../../qml/AmountValidator.qml")
        verify(component.status === Component.Ready, component.errorString())
        const validator = component.createObject(this)
        verify(validator !== null)
        const input = Qt.createQmlObject('import QtQuick; TextInput {}', this)
        input.validator = validator

        input.text = row.text
        compare(input.text, row.text)
        compare(input.acceptableInput, row.acceptable)

        input.destroy()
        validator.destroy()
    }
}
