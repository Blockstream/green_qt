FROM ubuntu:noble AS base
COPY ci/windows-x86_64/setup.sh .
RUN ./setup.sh
ENV PREFIX=/depends/windows-x86_64
ENV HOST=windows
ENV ARCH=x86_64
ENV PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig
ENV CMAKE_INSTALL_PREFIX=$PREFIX
ENV CMAKE_TOOLCHAIN_FILE=$PWD/cmake/mingw-w64-x86_64.cmake
ENV QT_HOST_PATH=/depends/linux-x86_64
COPY cmake cmake

FROM base AS gdk
COPY tools/buildgdk.sh tools/
RUN . /root/.cargo/env && tools/buildgdk.sh
RUN apt install -yqq mingw-w64-tools
RUN gendef build/gdk/build-windows-mingw-w64/src/libgreen_gdk.dll
RUN cp libgreen_gdk.def depends/windows-x86_64/lib

FROM base
COPY --from=gdk /depends /depends
