# Blockstream Green

Build status: [![Build Status](https://travis-ci.org/Blockstream/green_qt.png?branch=master)](https://travis-ci.org/Blockstream/green_qt)

## Before you build

### This README.md file assumes you are building for Windows and Linux on Ubuntu 18.04 and for OSX on latest OSX
### A 'Dockerfile' file is provided to build Linux and Windows binaries

```
cd green_qt && git submodule update --init --recursive
```

## Build all symbols unstripped

### Note: change 'linux' to 'osx' or 'windows' to build a full symbols build for OSX or Windows

### Note: skip the 'bionic_deps.sh' step for OSX

```
sudo ./tools/bionic_deps.sh
./tools/builddeps.sh linux allsymbolsunstripped
```

## Build static release on macOS

```
./tools/builddeps.sh osx
```

## Build static release on Linux

```
sudo ./tools/bionic_deps.sh
./tools/builddeps.sh linux
```

## Build static release on Linux for Windows

```
sudo ./tools/bionic_deps.sh
./tools/builddeps.sh windows
```

## Development in QtCreator

Building with QtCreator and dynamically linking with Qt and GDK is possible. For
now Qt is not built with -shared so one must be configured in QtCreator (see
Manage Kits dialog).
Just open the project green.pro and configure it with the kit of choice. Then
define the build environments BUILDROOT and GDKBLDID according the build done
from the previous steps. For instance, in macos these would look like:
```
BUILDROOT=build-osx-clang
GDKBLDID=0f8cef9fdf5f08fa8a33736a2e70d8e87b5260f19b46aa2f1a157bb8956b6280
```
