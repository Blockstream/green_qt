# C++ conventions

These notes apply to C++ under `src/` and project headers. They are part of the repository agent instructions; start from [AGENTS.md](../../AGENTS.md).

## Header file structure

```cpp
#ifndef GREEN_CLASSNAME_H
#define GREEN_CLASSNAME_H

#include "green.h"  // Project includes first (quoted)

#include <QObject>  // Qt includes (angled brackets)
#include <QQmlEngine>

Q_MOC_INCLUDE("dependency.h")  // For forward-declared QML types

class ClassName : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Type* property READ property WRITE setProperty NOTIFY propertyChanged)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    // Constructor, then public methods
private:
    Type* m_property{nullptr};  // Member variables with m_ prefix
};

#endif // GREEN_CLASSNAME_H
```

## Property pattern

For new simple writable properties, prefer this pattern:

```cpp
Q_PROPERTY(Type* name READ name WRITE setName NOTIFY nameChanged)
Q_PROPERTY(Type* name READ name CONSTANT)  // For immutable properties
```

- **Getter**: Returns member directly (`return m_name;`)
- **Setter**: Early return if unchanged, then set and emit signal
- **Signal**: Named `nameChanged` for one-property notifications, without signal arguments

```cpp
Type* name() const { return m_name; }
void setName(Type* name) {
    if (m_name == name) return;  // Always guard against no-op
    m_name = name;
    emit nameChanged();
}
```

Preserve aggregate notify patterns already used by a class. Many controllers and models intentionally expose several derived properties through one signal — examples in this codebase include:

- `ChartPriceService` (`src/chartpriceservice.h`) — `pricesDay`/`pricesWeek`/... on `pricesChanged`.
- `LedgerDevice` (`src/ledger/ledgerdevice.h`) — `appName`/`appVersion`/`compatible` on `appChanged`.
- `Controller` and subclasses (`src/controller.h`, `src/swapquotecontroller.h`) — multiple derived properties on `updated`.
- `Transaction`, `Address`, `Asset`, `Analytics`, `Promo`, `Payment`, `Output` — derived properties on `dataChanged`.

Do not split those into per-property signals unless the change needs independent notifications.

## Member variables

- Prefix all member variables with `m_`
- Use in-class initialization with braces: `{nullptr}`, `{false}`, `{0}`, `{-1}`
- `const` members for immutable references: `Network* const m_network;`

## Include order

1. Project headers (quoted): `#include "green.h"` or the closest local base header
2. Qt headers (angled): `#include <QObject>`
3. Third-party headers: `#include <gdk.h>`

Keep the ordering already used in the file when adding includes. Do not churn existing include blocks for unrelated cleanup.

## Class section order

1. Q_OBJECT macro
2. Q_PROPERTY declarations
3. QML_ELEMENT / QML_UNCREATABLE macros
4. public: (constructor first, then methods)
5. public slots:
6. signals:
7. protected:
8. private:

## Naming conventions

- **Classes**: PascalCase (`CreateTransactionController`)
- **Methods**: camelCase (`getOrCreateAccount`)
- **Members**: m_snake_case (`m_previous_transaction`)
- **Constants**: Use `const` with snake_case (`const QString m_deployment`)
- **Signals**: verbChanged or verbNoun (`accountChanged`, `transactionEvent`)

## QML integration

```cpp
QML_ELEMENT                    // Makes class available to QML
QML_UNCREATABLE("")           // For types created from C++ only
Q_MOC_INCLUDE("typename.h")   // For forward-declared types used in Q_PROPERTY

// For list properties exposed to QML:
Q_PROPERTY(QQmlListProperty<Account> accounts READ accounts NOTIFY accountsChanged)
QQmlListProperty<Account> accounts() { return { this, &m_accounts }; }
```

## Task class skeleton

For async operations, use the Task pattern (see also [architecture.md](architecture.md) for wiring tasks into flows):

```cpp
class MyTask : public AuthHandlerTask {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    MyTask(const QJsonObject& params, Session* session);
private:
    bool call(GA_session* session, GA_auth_handler** auth_handler) override;
    void handleDone(const QJsonObject& result) override;
private:
    const QJsonObject m_params;
};
```

Tasks should own only the data needed for the GDK call, generally as `const` members initialized in the constructor. Wire task sequencing through `TaskGroup`, `then(...)`, `monitor()`, and `dispatcher()` instead of starting ad hoc async work from QML.

## Error handling

- Use `Q_ASSERT` for invariants
- Early return pattern for null/invalid checks
- No exceptions - use error signals/properties
