# Repository layout and testing

Where things live and how to gate debug behavior. Part of the repository agent instructions; start from [AGENTS.md](../../AGENTS.md).

## File organization

- **src/**: C++ sources built into the `blockstream_core` static library, which also backs the `Blockstream.Green` QML module
    - **controllers/**, **models/**, **core/**: Grouped controllers, models and core helpers
    - **jade/**, **ledger/**, **lightning/**, **lwk/**, **glsdk/**: Device and protocol integrations
- **app/**: The `blockstream_app` executable target
    - **src/**: Entry point and process setup (`main.cpp`, `ui.cpp`, `sentry.cpp`, `watchdog.cpp`)
    - `Info.plist.in`, `production.rc`, `production.icns`, `production.ico`: Platform bundle metadata and app icons
- **qml/**: QML files (*.qml) and JavaScript (*.js)
- **cmake/**: Build modules (`AppLib.cmake`, `QmlModule.cmake`, `Platform*.cmake`, dependency finders)
- **i18n/**: Translation sources (`green_*.ts`)
- **tests/unit/**: Qt Test suites (`tst_*.cpp`) registered with CTest
- **tools/**: Dependency build scripts, packaging, `lint/` and `test.sh`
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
- For C++ changes, run `./tools/lint/cpplint.sh` when feasible; for QML/JS changes, `./tools/lint/qmllint.sh`.
- For added or removed QML files, update the file list in `qml/CMakeLists.txt`.
- For added or removed C++ files, update the `target_sources` of the closest `CMakeLists.txt` (`src/`, its subfolders, or `app/src/` for the executable).
- For behavior changes, run the narrowest relevant build or test target available in the checkout and mention the command in the handoff. Unit tests run with `./tools/test.sh all` or `./tools/test.sh one <suite_regex>`.

## Commit

Each commit should be reviewable on its own, compile when possible, and avoid mixing unrelated cleanup with feature logic.
