# Large feature work

Use this guide for larger changes such as wallet protocol support, cross-layer wallet flows, or any feature that spans core code, controllers, models, and QML. Start from [AGENTS.md](../../AGENTS.md), then read the relevant area guides.

## Patch shape

Large features must be split into reviewable stages. Avoid one broad patch that mixes protocol logic, controller wiring, UI, styling, tests, and cleanup.

Prefer this order:

1. Core/domain types, parsing, and data conversion
2. Task, activity, or controller wiring
3. Model/state exposure to QML
4. Minimal UI integration
5. Edge states, polish, and cleanup
6. Tests or focused verification for each stage

Each stage should compile on its own where possible. Do not expose unfinished production UI. If a later stage needs placeholders, keep them internal and clearly bounded.

## Feature design

- Start from the closest existing flow and copy its shape before adding new patterns. Inspect related transaction, task, controller, model, and QML code first.
- Keep data flow explicit: backend/domain call, then task or activity, then controller/model, then QML. Do not call wallet backend APIs directly from QML.
- Add the smallest useful abstraction. Do not create generic frameworks before concrete call sites need them.
- Keep QObject ownership and lifetimes consistent with nearby code. Be explicit about task ownership, model ownership, and dynamically created QML objects.
- Preserve wallet and session invariants. Be careful with active sessions, primary session assumptions, network-specific behavior, Liquid vs Bitcoin branching, watch-only wallets, hardware wallets, and authentication flows.
- Make unsupported states explicit with disabled actions, clear errors, or early returns. Do not leave partially working flows reachable.
- Keep UI and core changes separate when possible so protocol correctness can be reviewed without unrelated layout churn.

## Incomplete or gated work

- Do not expose incomplete flows in production UI.
- Gate debug-only or experimental UI behind existing debug or experimental settings.
- Keep existing behavior as the default until the new backend path is complete.
- Remove temporary logs, commented code, mock data, and local test hooks before handoff.

## Verification

Report verification per layer:

- Parser/domain logic: unit tests or focused fixtures where possible.
- Tasks/controllers: success, failure, cancellation, and invalid-input paths.
- QML: required properties, null/loading states, disabled states, and navigation cleanup.
- Build/list updates: CMake source lists, QML registration lists, assets, and translations.
- Manual flow notes when automated tests are not available.

A large feature is not ready for review if it only covers the happy path.
