FROM ubuntu:jammy AS base
COPY ci/linux-x86_64/setup.sh .
RUN ./setup.sh
ENV PREFIX=/depends/linux-x86_64
ENV HOST=linux
ENV ARCH=x86_64
ENV PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig
ENV CMAKE_INSTALL_PREFIX=$PREFIX

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

FROM base AS icu
COPY tools/buildicu.sh tools/
RUN tools/buildicu.sh

FROM base AS ffmpeg
COPY tools/buildffmpeg.sh tools/
RUN tools/buildffmpeg.sh

FROM base AS qt
COPY --from=ffmpeg /depends /depends
COPY --from=icu /depends /depends
COPY --from=gdk /build/gdk/build-gcc/external_deps/ /depends/linux-x86_64/
COPY tools/buildqt.sh tools/
RUN tools/buildqt.sh

FROM qt AS kdsa
COPY tools/buildkdsingleapplication.sh tools/
RUN tools/buildkdsingleapplication.sh

FROM base AS libserialport
COPY tools/buildlibserialport.sh tools/buildlibserialport.sh tools/
RUN tools/buildlibserialport.sh

FROM base AS crashpad
COPY --from=gdk /build/gdk/build-gcc/external_deps/ /depends/linux-x86_64/
ENV OPENSSL_ROOT_DIR=$PREFIX
COPY tools/buildlibcurl.sh tools/
RUN tools/buildlibcurl.sh
ENV CMAKE_PREFIX_PATH=$PREFIX
COPY tools/buildcrashpad.sh tools/
RUN tools/buildcrashpad.sh

FROM base AS breakpad
COPY tools/buildbreakpad.sh tools/
RUN tools/buildbreakpad.sh

FROM base AS gpgme
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
