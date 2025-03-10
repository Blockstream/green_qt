# Architecture

This document contais some implemention details of Blockstream Green for desktop.

### Dependencies

Used dependencies in alphabetic order:

| Dependency | Usage |
| - | - |
| [Breakpad](https://chromium.googlesource.com/breakpad/breakpad/) | Process minidump files |
| [Countly](https://github.com/Countly/countly-sdk-cpp) | Track analytics |
| [Crashpad](https://chromium.googlesource.com/crashpad/crashpad/+/HEAD/README.md) | Handle crashes and minidump creation |
| [GDK](https://gdk.readthedocs.io) | Green Development Kit
[libserialport](https://sigrok.org/wiki/Libserialport) | Enumerate serial port devices |
| [Qt](https://qt.io) | Cross plaform development framework |
| [ZXing](https://github.com/zxing-cpp/zxing-cpp) | Encode and decode QR Codes |

### Multiprocess

When the application is started, 3 processes are launched:
- watchdog: this is the first and is responsible for starting the user interface and restarting after a crash;
- user interface: the main process, responsible for the application window, interacting with hardware devices, etc;
- crash handler: responsible for creating the minidump file in a safe way.

All behaviors are implemented in the same binary:
- user interface: runs when `--ui` argument is set;
- crash handler: runs when `--database` argument is set;
- watchdog: runs when none above the above is set.

### Crash Reports

The application integrates [Crashpad](https://chromium.googlesource.com/crashpad/crashpad/+/HEAD/README.md) for crash-reporting support. The minidump file (OS-agnostic snapshot of the crashed process) is stored locally until it is processed, then it is removed from the filesystem.

Usually a Crashpad integration uploads the minidump to a server for remote processing, but this has privacy and security implications, thus uploading minidumps is not implemented. For this reason, the application integrates [Breakpad](https://chromium.googlesource.com/breakpad/breakpad/) to process minidumps locally. The result is a stack trace of the crashed thread, which is then reported to Blockstream incident server.
