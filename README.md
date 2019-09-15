# Blockstream Green

Build status: [![Build Status](https://travis-ci.org/Blockstream/green_qt.png?branch=master)](https://travis-ci.org/Blockstream/green_qt)

## Before you build

```
cd green_qt && git submodule update --init --recursive
```

## Build on macOS

```
./tools/builddeps.sh osx
```

## Build on Linux

```
sudo ./tools/bionic_deps.sh
./tools/builddeps.sh
```

## Build on Linux for Windows

```
sudo ./tools/bionic_deps.sh
./tools/builddeps.sh windows
```
