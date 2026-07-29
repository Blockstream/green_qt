# Repository layout and testing

Where things live and how to gate debug behavior. Part of the repository agent instructions; start from [AGENTS.md](../../AGENTS.md).

## File organization

- **src/**: C++ source files (*.cpp, *.h)
- **qml/**: QML files (*.qml) and JavaScript (*.js)
- **assets/**: Icons, images, fonts
    - **icons/**: App branding icons plus monochrome UI glyphs (`*.svg`) tinted at runtime
    - **svg/**, **svg2/**, **svg3/**: Legacy themed SVG trees (still registered in `assets/CMakeLists.txt`)
    - **flags/**: Country flag SVGs
    - **fonts/**: TTF fonts
    - **png/**, **pdf/**, **installer/**: Other static assets

### Monochrome UI icons (`assets/icons/*.svg`)

UI glyphs are stored **once** as white (`#FFFFFF`) SVGs under `assets/icons/`. Tint and display size are QML concerns — do **not** add color- or size-keyed folders like `assets/<hex>/<size>/`.

```text
assets/icons/arrows-down-up.svg
assets/icons/clipboard.svg
assets/icons/note.svg
```

In QML, load via `ColorIcon` (standalone) or `icon.source` + `icon.color` on buttons that forward color through `ColorIcon`:

```qml
ColorIcon {
    source: 'qrc:/icons/list-checks.svg'
    color: '#000000'
    width: 24
    height: 24
}

PrimaryButton {
    icon.source: 'qrc:/icons/clipboard.svg'
    icon.color: '#000000'
}
```

`ColorIcon` colorizes only when `color.a > 0`. Leave `icon.color` as `'transparent'` (the default on project buttons) to keep multi-color / legacy assets unchanged.

When adding or renaming a file under `assets/icons/`, **append it to the `FILES` list** in [assets/CMakeLists.txt](../../assets/CMakeLists.txt) inside the `qt_add_resources(..., "images")` block, or the icon will not ship in the build. Multi-color brand art (Jade, logos, watermarks, flags) stays in the legacy trees and should not be colorized.

## Testing considerations

- Use `Qt.application.arguments.indexOf('--debug') > 0` for debug-only features
- Add `visible: false` to hide development/debug UI elements
- Use `Component.onCompleted` for initialization that needs to happen once

## Build and review checks

- Keep commit subjects compatible with commitlint: the subject must start with an uppercase letter, for example `ui: Add receive warning`.
- For C++ changes, run `./tools/lint/cpplint.sh` when feasible.
- For added or removed QML files, update the QML registration/build lists such as `qml.cmake` and `qml/CMakeLists.txt`.
- For CMake/source-list changes, update the closest relevant `CMakeLists.txt` in the same patch.
- For behavior changes, run the narrowest relevant build or test target available in the checkout and mention the command in the handoff.

## Commit

Each commit should be reviewable on its own, compile when possible, and avoid mixing unrelated cleanup with feature logic.
