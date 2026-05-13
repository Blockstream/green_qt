# Common mistakes

Cross-layer pitfalls to avoid when editing this codebase. Part of the repository agent instructions; start from [AGENTS.md](../../AGENTS.md).

1. **Don't forget early returns in setters**
   ```cpp
   // Bad
   void setName(Type* name) { m_name = name; emit nameChanged(); }

   // Good
   void setName(Type* name) {
       if (m_name == name) return;
       m_name = name;
       emit nameChanged();
   }
   ```

2. **Don't use `this` in QML - use `self`**
   ```qml
   // Bad
   text: this.account.name

   // Good
   text: self.account.name
   ```

3. **Don't crash on null - use optional chaining**
   ```qml
   // Bad
   text: controller.transaction.error

   // Good
   text: controller.transaction?.error ?? ''
   ```

4. **Don't forget Layout.fillWidth for buttons in layouts**
   ```qml
   PrimaryButton {
       Layout.fillWidth: true  // Required!
       text: 'Submit'
   }
   ```

5. **Don't leave dead or commented-out code**
   ```qml
   // Bad: keeping an unused alternate UI in a block comment
   /*
   RowLayout {
       // old implementation
   }
   */

   // Good: delete code that is no longer used
   ```

6. **Don't replace translation ids with literals**
   ```qml
   // Bad
   text: 'Cancel'

   // Good
   text: qsTrId('id_cancel')
   ```

7. **Don't use default padding - be explicit**
   ```qml
   // Bad
   Pane { }

   // Good
   Pane {
       padding: 20
       leftPadding: 12
       rightPadding: 12
   }
   ```

8. **Don't mix camelCase and snake_case for IDs**
   ```qml
   // Bad
   id: amountInput

   // Good
   id: amount_input
   ```

9. **Don't use string colors without quotes**
   ```qml
   // Bad
   color: #FFFFFF

   // Good
   color: '#FFFFFF'
   ```

10. **Don't add files without build-list updates**
    ```text
    If you add qml/NewPage.qml, update the QML registration/build list in the same change.
    If you add C++ sources, update the relevant CMake source list in the same change.
    ```
