#!/bin/bash
set -eox pipefail

apt update -qq
apt install -yqq --no-install-recommends --no-install-suggests software-properties-common curl ca-certificates wget

apt-get upgrade --no-install-recommends --no-install-suggests -yqq
apt-get install --no-install-recommends --no-install-suggests -yqq cmake clang unzip git automake autoconf pkg-config libtool build-essential ninja-build llvm-19-dev llvm-19-tools libllvm19 libclang-19-dev python3-venv python3-pip python3-setuptools virtualenv libgl1-mesa-dev libfontconfig1-dev libfreetype6-dev libx11-dev libxext-dev libxfixes-dev libxi-dev libxrender-dev libxcb1-dev libxkbcommon-dev libx11-xcb-dev libxcb-glx0-dev libxkbcommon-x11-dev libd3dadapter9-mesa-dev libegl1-mesa-dev libgles2-mesa-dev software-properties-common gstreamer1.0-gl gstreamer1.0-plugins-base libgstreamer-gl1.0-0 libgstreamer-plugins-base1.0-0 libgstreamer-plugins-base1.0-dev libgstreamer1.0-0 libgstreamer1.0-dev g++-mingw-w64-x86-64 ccache libxcb-keysyms1-dev libxcb-image0-dev libxcb-shm0-dev libxcb-icccm4-dev libxcb-sync0-dev libxcb-xfixes0-dev libxcb-shape0-dev libxcb-randr0-dev libxcb-render-util0-dev libxcb-util-dev libxcb-xinerama0-dev libxcb-xkb-dev libxcb-xinput-dev libxcb-xinerama0-dev libx11-xcb-dev libxcb-xkb-dev libxcb-xinput-dev libxcb-glx0-dev libxcb-keysyms1-dev libxcb-image0-dev libxcb-shm0-dev libxcb-icccm4-dev libxcb-sync0-dev libxcb-xfixes0-dev libxcb-shape0-dev libxcb-randr0-dev libxcb-render-util0-dev libudev-dev libbluetooth-dev bluez libdbus-1-dev libpulse-dev mingw-w64 libcurl4-openssl-dev
#update-alternatives --set x86_64-w64-mingw32-g++ /usr/bin/x86_64-w64-mingw32-g++-posix


curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain 1.65.0
source /root/.cargo/env
rustup target add x86_64-pc-windows-gnu
