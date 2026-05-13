# Agent instructions: Blockstream Green Qt

## Audience

Human contributors and automated coding assistants should follow these instructions so changes stay consistent and pass review. This layout is **not tied to a single editor or vendor**: any tool that can read markdown can use the root file and the guides under `doc/agents/`.

## Project overview

This is a cross-platform Bitcoin/Liquid wallet using Qt 6 and QML. It integrates with hardware wallets (Jade, Ledger) and the Green Development Kit (GDK).

## General direction

- Prefer **small, focused changes** that match patterns already present in the files you touch.
- Treat nearby code as the strongest style guide. If these docs and local precedent differ, follow the local pattern and keep the change consistent with that file.
- Avoid broad cleanups, opportunistic refactors, and visual restyles unless they are part of the task. Do not leave commented-out alternate implementations behind.
- **Open the area guides that apply** to your task before editing; conventions here deliberately override generic Qt/QML habits where they differ.
- In **QML**, prefer **optional chaining**, **nullish coalescing**, root id **`self`**, and the shared **layout and styling** patterns in [doc/agents/qml.md](doc/agents/qml.md).
- In **C++**, follow **include order**, **Q_PROPERTY** setters with early return, and **signal naming** in [doc/agents/cpp.md](doc/agents/cpp.md); wire async work through **controllers and tasks** as in [doc/agents/architecture.md](doc/agents/architecture.md).
- For larger features such as wallet protocol support or cross-layer wallet flows, split work into reviewable layers as described in [doc/agents/large-features.md](doc/agents/large-features.md).
- Review [doc/agents/pitfalls.md](doc/agents/pitfalls.md) for frequent review feedback across layers.
- For **CI**, **build scripts**, or **doc build instructions**, keep platform variants and docs in sync — see [doc/agents/ci.md](doc/agents/ci.md).

## Review posture

- Keep diffs easy to review: one behavior change per patch where possible, with related build/list updates in the same patch.
- Prefer existing project components, controllers, tasks, and QML helpers over new abstractions.
- Preserve user-facing behavior unless the task explicitly changes it; be especially careful around wallet state, sessions, authentication, and transaction flows.
- For user-facing QML text, reuse existing `qsTrId(...)` ids when available. Avoid new hardcoded English unless the surrounding feature deliberately uses literals or the string is internal/debug-only.
- Before handing off, run the narrowest relevant lint, build, or test command you can and report what was or was not run.

## Area guides

- **C++** (`src/`, headers): [doc/agents/cpp.md](doc/agents/cpp.md)
- **QML** (`qml/`): [doc/agents/qml.md](doc/agents/qml.md)
- **JavaScript** (inline and `.js` with QML): [doc/agents/javascript.md](doc/agents/javascript.md)
- **Controllers, GDK tasks, models**: [doc/agents/architecture.md](doc/agents/architecture.md)
- **CI, build scripts, platform docs**: [doc/agents/ci.md](doc/agents/ci.md)
- **Repository layout, assets, testing hooks**: [doc/agents/repository.md](doc/agents/repository.md)
- **Large features** (wallet protocols, cross-layer flows): [doc/agents/large-features.md](doc/agents/large-features.md)
- **Common mistakes**: [doc/agents/pitfalls.md](doc/agents/pitfalls.md)

When a task spans several areas, read each applicable guide.
