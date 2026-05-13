# Architecture patterns

How controllers, tasks, and models fit together. Part of the repository agent instructions; start from [AGENTS.md](../../AGENTS.md). For C++ class layout and `AuthHandlerTask` skeletons, see [cpp.md](cpp.md).

## Controller pattern

Controllers hold business logic and are exposed to QML:

```cpp
class MyController : public Controller {
    Q_PROPERTY(Account* account READ account WRITE setAccount NOTIFY accountChanged)
    Q_PROPERTY(QJsonObject result READ result NOTIFY resultChanged)
public slots:
    void submit();
signals:
    void accountChanged();
    void resultChanged();
};
```

```qml
MyController {
    id: controller
    context: self.context
    account: self.account
}
```

## Task pattern (async GDK)

For async GDK operations:

```cpp
auto task = new MyTask(params, session);
connect(task, &Task::finished, this, [=] {
    // Handle success
});
connect(task, &Task::failed, this, [=](const QString& error) {
    // Handle failure
});
group->add(task);
```

## Model pattern

Use QSortFilterProxyModel for filtered views:

```cpp
class MyModel : public ContextModel {
protected:
    bool filterAcceptsRow(int source_row, const QModelIndex& source_parent) const override;
    void update(Context* context) override;
};
```
