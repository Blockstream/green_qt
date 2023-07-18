FROM ubuntu:bionic AS base
COPY ci/linux-x86_64/bionic.sh .
RUN ./bionic.sh
ENV PREFIX=/depends/linux-x86_64
ENV HOST=linux
ENV ARCH=x86_64
ENV PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig
ENV CMAKE_INSTALL_PREFIX=$PREFIX
RUN ln -s /usr/bin/python3.8 /usr/bin/python3.10

FROM base AS hidapi
COPY tools/buildlibusb.sh tools/buildhidapi.sh tools/
RUN tools/buildlibusb.sh && tools/buildhidapi.sh

FROM base AS countly
COPY tools/buildcountly.sh tools/
RUN tools/buildcountly.sh

FROM base AS gdk
COPY tools/buildgdk.sh tools/
RUN . /root/.cargo/env && tools/buildgdk.sh

FROM base AS qt
COPY tools/buildqt.sh tools/
COPY tools/patches/ tools/patches/
RUN tools/buildqt.sh

FROM base
COPY --from=hidapi /depends /depends
COPY --from=countly /depends /depends
COPY --from=gdk /depends /depends
COPY --from=qt /depends /depends
