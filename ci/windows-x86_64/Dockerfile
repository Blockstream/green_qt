FROM ubuntu:oracular AS base
COPY ci/windows-x86_64/lunar.sh .
RUN ./lunar.sh
ENV PREFIX=/depends/windows-x86_64
ENV HOST=windows
ENV ARCH=x86_64
ENV PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig
ENV CMAKE_INSTALL_PREFIX=$PREFIX
ENV CMAKE_TOOLCHAIN_FILE=$PWD/cmake/mingw-w64-x86_64.cmake
ENV QT_HOST_PATH=/depends/linux-x86_64
COPY cmake cmake

FROM base AS hidapi
COPY tools/buildlibusb.sh tools/buildhidapi.sh tools/
RUN tools/buildlibusb.sh && tools/buildhidapi.sh

FROM base AS countly
COPY tools/buildcountly.sh tools/
RUN tools/buildcountly.sh

FROM base AS gdk
COPY tools/buildgdk.sh tools/
RUN . /root/.cargo/env && tools/buildgdk.sh

FROM base AS zxing
COPY tools/buildzxing.sh tools/
RUN tools/buildzxing.sh

FROM base AS qt
COPY tools/buildqt.sh tools/
RUN tools/buildqt.sh

FROM qt AS kdsa
COPY tools/buildkdsingleapplication.sh tools/
RUN tools/buildkdsingleapplication.sh

FROM base AS libserialport
COPY tools/buildlibserialport.sh tools/buildlibserialport.sh tools/
RUN tools/buildlibserialport.sh

FROM base AS crashpad
COPY tools/buildcrashpad.sh tools/
RUN tools/buildcrashpad.sh

FROM base
COPY --from=hidapi /depends /depends
COPY --from=countly /depends /depends
COPY --from=zxing /depends /depends
COPY --from=gdk /depends /depends
COPY --from=kdsa /depends /depends
COPY --from=libserialport /depends /depends
COPY --from=crashpad /depends /depends
