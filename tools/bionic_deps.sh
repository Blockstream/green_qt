#!/bin/bash
set -eo pipefail

. /qtversion.env
if [ -f /.dockerenv ]; then
    if [ -f /bionic_hash ]; then
        bionic_deps_sha256=$(< /bionic_hash)
        echo "${bionic_deps_sha256} tools/bionic_deps.sh" | sha256sum --check --strict --status && exit 0 || true
    fi
fi


apt-get update -qq
apt-get install -yqq --no-install-recommends --no-install-suggests software-properties-common curl

add-apt-repository ppa:cybermax-dexter/mingw-w64-backport

curl -sL -o gcc10.deb http://ge.archive.ubuntu.com/ubuntu/pool/main/g/gcc-10/gcc-10-base_10-20200411-0ubuntu1_amd64.deb
curl -sL -o libgcc.deb  http://es.archive.ubuntu.com/ubuntu/pool/main/g/gcc-10/libgcc-s1_10-20200411-0ubuntu1_amd64.deb

dpkg -i *.deb
rm *.deb

apt-get upgrade --no-install-recommends --no-install-suggests -yqq
apt-get install --no-install-recommends --no-install-suggests -yqq clang ca-certificates unzip git automake autoconf pkg-config libtool build-essential ninja-build llvm-dev python3-pip python3-setuptools virtualenv libgl1-mesa-dev python libfontconfig1-dev libfreetype6-dev libx11-dev libxext-dev libxfixes-dev libxi-dev libxrender-dev libxcb1-dev libx11-xcb-dev libxcb-glx0-dev libxkbcommon-x11-dev libd3dadapter9-mesa-dev libegl1-mesa-dev libgles2-mesa-dev software-properties-common gstreamer1.0-gl gstreamer1.0-plugins-base libgstreamer-gl1.0-0 libgstreamer-plugins-base1.0-0 libgstreamer-plugins-base1.0-dev libgstreamer1.0-0 libgstreamer1.0-dev g++-mingw-w64-x86-64

update-alternatives --set x86_64-w64-mingw32-g++ /usr/bin/x86_64-w64-mingw32-g++-posix

curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain 1.43.0
source /root/.cargo/env
rustup target add x86_64-pc-windows-gnu


if [ ! -d /qt-everywhere-src-${QTVERSION} ]; then
   curl -sL -o qt-everywhere-src-${QTVERSION}.tar.xz https://download.qt.io/archive/qt/${QTMAJOR}/${QTVERSION}/single/qt-everywhere-src-${QTVERSION}.tar.xz
   echo "${QTHASH} qt-everywhere-src-${QTVERSION}.tar.xz" | sha256sum --check --strict
   tar xf qt-everywhere-src-${QTVERSION}.tar.xz
   rm qt-everywhere-src-${QTVERSION}.tar.xz
fi

if [ -f /.dockerenv ]; then
    sha256sum /bionic_deps.sh | cut -d" " -f1 > /bionic_hash
    apt -yqq autoremove
    apt -yqq clean
    rm -rf /var/lib/apt/lists/* /var/cache/* /tmp/* /usr/share/locale/* /usr/share/man /usr/share/doc /lib/xtables/libip6* /root/.cache /bionic_deps.sh
fi
