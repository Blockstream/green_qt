#!/bin/bash
set -eo pipefail

if [ -f /.dockerenv ]; then
    if [ -f /bionic_hash ]; then
        bionic_deps_sha256=$(< /bionic_hash)
        echo "${bionic_deps_sha256} tools/bionic_deps.sh" | sha256sum --check --strict --status && exit 0 || true
    fi
fi

apt-get update -yqq
apt-get upgrade --no-install-recommends -yqq
apt-get install --no-install-recommends -yqq clang curl ca-certificates unzip git automake autoconf pkg-config libtool build-essential ninja-build llvm-dev python3-pip python3-setuptools virtualenv libgl1-mesa-dev python g++-mingw-w64-x86-64 libfontconfig1-dev libfreetype6-dev libx11-dev libxext-dev libxfixes-dev libxi-dev libxrender-dev libxcb1-dev libx11-xcb-dev libxcb-glx0-dev libxkbcommon-x11-dev libd3dadapter9-mesa-dev libegl1-mesa-dev libgles2-mesa-dev

update-alternatives --set x86_64-w64-mingw32-g++ /usr/bin/x86_64-w64-mingw32-g++-posix

curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain 1.39.0
source /root/.cargo/env
rustup target add x86_64-pc-windows-gnu


if [ ! -d /qt-everywhere-src-5.13.2 ]; then
   curl -sL -o qt-everywhere-src-5.13.2.tar.xz https://download.qt.io/archive/qt/5.13/5.13.2/single/qt-everywhere-src-5.13.2.tar.xz
   echo "55e8273536be41f4f63064a79e552a22133848bb419400b6fa8e9fc0dc05de08 qt-everywhere-src-5.13.2.tar.xz" | sha256sum --check --strict
   tar xf qt-everywhere-src-5.13.2.tar.xz
   rm qt-everywhere-src-5.13.2.tar.xz
fi

if [ -f /.dockerenv ]; then
    sha256sum /bionic_deps.sh | cut -d" " -f1 > /bionic_hash
    apt -yqq autoremove
    apt -yqq clean
    rm -rf /var/lib/apt/lists/* /var/cache/* /tmp/* /usr/share/locale/* /usr/share/man /usr/share/doc /lib/xtables/libip6* /root/.cache
fi
