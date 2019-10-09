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
