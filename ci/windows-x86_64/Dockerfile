FROM ubuntu:kinetic AS base
COPY ci/windows-x86_64/kinetic.sh .
RUN ./kinetic.sh
ENV PREFIX=/depends/windows-x86_64
ENV HOST=windows
ENV ARCH=x86_64
ENV PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig
ENV CMAKE_INSTALL_PREFIX=$PREFIX
ENV CMAKE_TOOLCHAIN_FILE=$PWD/cmake/mingw-w64-x86_64.cmake
ENV QT_HOST_PATH=/depends/linux-x86_64
COPY tools tools
COPY cmake cmake

FROM base AS builder
RUN . /root/.cargo/env && tools/builddeps.sh

FROM base
COPY --from=builder /depends /depends
