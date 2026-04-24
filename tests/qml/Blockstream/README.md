# QML test stubs

These modules stand in for the C++ types registered from `src/` (mainly
`src/green.h`, `src/models/*` and `src/models/transaction.h`) so components in
`qml/` can be loaded by `qmltestrunner` without the app.

They only mirror the properties and methods the tested components use, and the
types are simplified: for example `ContextModel.filterAccounts` is a JS array
here but a `QQmlListProperty<Account>` in C++. When a tested component starts
using a new property, or the C++ API changes, update the matching stub.
