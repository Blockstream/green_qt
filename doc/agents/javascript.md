# JavaScript in QML

Conventions for `.js` files and inline script in QML. Part of the repository agent instructions; start from [AGENTS.md](../../AGENTS.md).

## Function style

```javascript
function functionName(param) {
    // Use const for immutable values
    const result = someComputation()

    // Early return for guards
    if (!param) return ''

    // Template literals for strings
    return `Value: ${result}`
}
```

## Arrow functions

Use in callbacks and QML signal handlers:

```qml
onSelected: (account) => {
    self.account = account
    self.StackView.view.pop()
}
```

## Null checks

```javascript
// Always check arrays and objects defensively
if (!config || typeof config !== 'object' || Array.isArray(config)) {
    return defaultValue
}

const values = config[key]
if (values && Array.isArray(values) && values.length > 0) {
    return values.map(val => val.toString())
}
```
