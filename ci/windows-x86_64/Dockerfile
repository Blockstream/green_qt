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
RUN install -d $PREFIX/bin
RUN install build/gdk/build-windows-mingw-w64/src/libgreen_gdk.dll $PREFIX/bin
RUN cd $PREFIX/bin && gendef libgreen_gdk.dll

FROM base as libserialport
COPY tools/buildlibserialport.sh tools/buildlibserialport.sh tools/
RUN tools/buildlibserialport.sh
RUN apt install -yqq mingw-w64-tools
RUN cd $PREFIX/bin && gendef libserialport-0.dll

FROM base
COPY --from=gdk /depends /depends
COPY --from=libserialport /depends /depends
