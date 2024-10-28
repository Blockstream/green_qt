#!/bin/bash
set -eox pipefail

apt update -qq
apt install -yqq --no-install-recommends --no-install-suggests software-properties-common curl ca-certificates wget

curl -L -o cmake.sh https://github.com/Kitware/CMake/releases/download/v3.26.0-rc3/cmake-3.26.0-rc3-linux-x86_64.sh
chmod +x cmake.sh
./cmake.sh --skip-license --prefix=/usr
rm cmake.sh

apt-get install --no-install-recommends --no-install-suggests -yqq unzip git automake autoconf pkg-config libtool build-essential ninja-build virtualenv libgl1-mesa-dev libfontconfig1-dev libfreetype6-dev libx11-dev libxext-dev libxfixes-dev libxi-dev libxrender-dev libxcb1-dev libxkbcommon-dev libx11-xcb-dev libxcb-glx0-dev libxkbcommon-x11-dev libd3dadapter9-mesa-dev libegl1-mesa-dev libgles2-mesa-dev software-properties-common gstreamer1.0-gl gstreamer1.0-plugins-base libgstreamer-gl1.0-0 libgstreamer-plugins-base1.0-0 libgstreamer-plugins-base1.0-dev libgstreamer1.0-0 libgstreamer1.0-dev g++-mingw-w64-x86-64 ccache libxcb-keysyms1-dev libxcb-image0-dev libxcb-shm0-dev libxcb-icccm4-dev libxcb-sync0-dev libxcb-xfixes0-dev libxcb-shape0-dev libxcb-randr0-dev libxcb-render-util0-dev libxcb-util-dev libxcb-xinerama0-dev libxcb-xkb-dev libxcb-xinput-dev libxcb-xinerama0-dev libx11-xcb-dev libxcb-xkb-dev libxcb-xinput-dev libxcb-glx0-dev libxcb-keysyms1-dev libxcb-image0-dev libxcb-shm0-dev libxcb-icccm4-dev libxcb-sync0-dev libxcb-xfixes0-dev libxcb-shape0-dev libxcb-randr0-dev libxcb-render-util0-dev libudev-dev libbluetooth-dev bluez libdbus-1-dev libpulse-dev libwayland-dev libcurl4-openssl-dev linux-libc-dev python3-venv libx11-dev libxcb1-dev libxext-dev libxi-dev libxcomposite-dev libxcursor-dev libxtst-dev libxrandr-dev libx11-xcb-dev libxext-dev libxfixes-dev libxi-dev libxrender-dev libxcb1-dev libxcb-glx0-dev libxcb-keysyms1-dev libxcb-image0-dev libxcb-shm0-dev libxcb-icccm4-dev libxcb-sync-dev libxcb-xfixes0-dev libxcb-shape0-dev libxcb-randr0-dev libxcb-render-util0-dev libxcb-util0-dev libxcb-xinerama0-dev libxcb-xkb-dev libxkbcommon-dev libxkbcommon-x11-dev libxcb-xinput-dev libxcb-cursor-dev 

apt-get install --no-install-recommends --no-install-suggests -yqq clang-12 libclang-12-dev llvm-12-dev libc++-12-dev
# bash -c "$(wget -O - https://apt.llvm.org/llvm.sh)"

curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain 1.68.0
source /root/.cargo/env

update-alternatives --set x86_64-w64-mingw32-g++ /usr/bin/x86_64-w64-mingw32-g++-posix
update-alternatives \
  --install /usr/bin/clang                 clang                  /usr/bin/clang-12     20 \
  --slave   /usr/bin/clang++               clang++                /usr/bin/clang++-12

