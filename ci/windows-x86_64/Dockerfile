FROM ubuntu:plucky AS base
COPY ci/windows-x86_64/setup.sh .
RUN ./setup.sh
ENV PREFIX=/depends/windows-x86_64
ENV HOST=windows
ENV ARCH=x86_64
ENV PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig
ENV CMAKE_INSTALL_PREFIX=$PREFIX
ENV CMAKE_TOOLCHAIN_FILE=$PWD/cmake/mingw-w64-x86_64.cmake
ENV QT_HOST_PATH=/depends/linux-x86_64
ENV PATH="$PREFIX/bin/:$PATH"
COPY cmake cmake

FROM base AS hidapi
COPY tools/buildlibusb.sh tools/buildhidapi.sh tools/
RUN tools/buildlibusb.sh && tools/buildhidapi.sh

FROM base AS countly
COPY tools/buildcountly.sh tools/
RUN tools/buildcountly.sh

FROM base AS gdk
COPY tools/buildgdk.sh tools/
RUN . /root/.cargo/env && tools/buildgdk.sh --static

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
RUN tools/buildlibserialport.sh --disable-shared

FROM ubuntu:jammy AS uasm
RUN apt update && \
    apt install -y build-essential wget && \
    wget https://github.com/Terraspace/UASM/archive/refs/tags/v2.57r.tar.gz && \
    tar zxvf v2.57r.tar.gz && \
    cd UASM-2.57r && make -f Makefile-Linux-GCC-64.mak && \
    cp /UASM-2.57r/GccUnixR/uasm /usr/bin

FROM base AS crashpad
COPY --from=uasm /usr/bin/uasm /usr/bin
COPY tools/buildcrashpad.sh tools/
RUN tools/buildcrashpad.sh

FROM base AS breakpad
COPY tools/buildbreakpad.sh tools/
RUN tools/buildbreakpad.sh

FROM base AS gpgme
RUN apt install -y gettext
COPY tools/buildgpgme.sh tools/
RUN tools/buildgpgme.sh

FROM base
COPY --from=hidapi /depends /depends
COPY --from=countly /depends /depends
COPY --from=zxing /depends /depends
COPY --from=gdk /depends /depends
COPY --from=kdsa /depends /depends
COPY --from=libserialport /depends /depends
COPY --from=crashpad /depends /depends
COPY --from=breakpad /depends /depends
COPY --from=gpgme /depends /depends
