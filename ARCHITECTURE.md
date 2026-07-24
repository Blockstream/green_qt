# Architecture

This document contains implementation details for the desktop Blockstream app.

### Dependencies

Used dependencies in alphabetic order:

| Dependency | Usage |
| - | - |
| [Countly](https://github.com/Countly/countly-sdk-cpp) | Track analytics |
| [GDK](https://gdk.readthedocs.io) | Green Development Kit
[libserialport](https://sigrok.org/wiki/Libserialport) | Enumerate serial port devices |
| [Qt](https://qt.io) | Cross plaform development framework |
| [sentry-native](https://github.com/getsentry/sentry-native) | Capture and report crashes (Crashpad backend) |
| [ZXing](https://github.com/zxing-cpp/zxing-cpp) | Encode and decode QR Codes |

### Multiprocess

When the application is started, the following processes are launched:
- watchdog: this is the first and is responsible for starting the user interface and restarting after a crash;
- user interface: the main process, responsible for the application window, interacting with hardware devices, etc;
- crash handler: the `crashpad_handler` executable bundled by sentry-native, spawned by the user interface process to capture crashes in a safe way.

The watchdog and user interface behaviors are implemented in the same binary:
- user interface: runs when `--ui` argument is set;
- watchdog: runs otherwise.

### Crash Reports

The application integrates [sentry-native](https://github.com/getsentry/sentry-native) (with its Crashpad backend) for crash-reporting support. On a crash, the bundled `crashpad_handler` captures a minidump and the sentry-native SDK reports it to Blockstream's self-hosted Sentry server.

Because a wallet's memory and registers can hold secrets, Crashpad is patched (see `tools/patches`, applied when it is built) so that an uploaded minidump carries no process memory and no register state, and names no local account in module paths. Stack traces survive that stripping: they are walked at capture time and travel in sentry-native's own client-side stack-trace stream. `tools/check-minidump.py` verifies a dump.
