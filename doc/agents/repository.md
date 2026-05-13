# Repository layout and testing

Where things live and how to gate debug behavior. Part of the repository agent instructions; start from [AGENTS.md](../../AGENTS.md).

## File organization

- **src/**: C++ source files (*.cpp, *.h)
- **qml/**: QML files (*.qml) and JavaScript (*.js)
- **assets/**: Icons, images, fonts
  - **svg/**, **svg2/**, **svg3/**: Legacy themed SVG trees (still registered in `assets/CMakeLists.txt`)
  - **flags/**: Country flag SVGs
  - **fonts/**: TTF fonts
  - **png/**, **pdf/**, **icons/**, **installer/**: Other static assets

### Color-keyed icons (`assets/<color>/<size>/`)

Newer UI icons live under a path shaped like **`assets/<hex-color>/<pixel-size>/<name>.svg`**:

```text
assets/fafafa/20/arrows-down-up.svg
assets/a0a0a0/24/faders-horizontal.svg
assets/ffffff/16/note.svg
assets/000000/24/list-checks.svg
```

- **`<color>`** — Lowercase hex **without** `#` (e.g. `fafafa`, `a0a0a0`, `ffffff`, `000000`), matching the intended stroke/fill on dark UI.
- **`<size>`** — Nominal icon size in pixels (`16`, `20`, `24`, …).
- **`<name>.svg`** — File name; use the same name when the same glyph exists in another color/size.

In QML, reference them via the Qt resource prefix (files are registered from `assets/` with `BASE .`):

```qml
icon.source: 'qrc:/fafafa/20/arrows-down-up.svg'
```

When adding or renaming a file under a color/size folder, **append it to the `FILES` list** in [assets/CMakeLists.txt](../../assets/CMakeLists.txt) inside the `qt_add_resources(..., "images")` block, or the icon will not ship in the build.

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
