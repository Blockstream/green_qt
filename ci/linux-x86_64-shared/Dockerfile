FROM ubuntu:jammy AS base0
COPY ci/linux-x86_64-shared/setup.sh .
RUN ./setup.sh
ENV PREFIX=/depends/linux-x86_64
ENV HOST=linux
ENV ARCH=x86_64
ENV PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig
ENV CMAKE_INSTALL_PREFIX=$PREFIX

FROM base0 AS base
RUN curl -L -O https://download.qt.io/official_releases/online_installers/qt-online-installer-linux-x64-online.run
RUN chmod +x qt-online-installer-linux-x64-online.run
ARG QT_INSTALLER_JWT_TOKEN
ENV QT_INSTALLER_JWT_TOKEN=${QT_INSTALLER_JWT_TOKEN}
RUN ./qt-online-installer-linux-x64-online.run --root /qt --accept-licenses --default-answer --confirm-command --accept-obligations install qt.qt6.683.linux_gcc_64 qt.qt6.683.addons.qt5compat qt.qt6.683.addons.qtconnectivity qt.qt6.683.addons.qtmultimedia qt.qt6.683.addons.qtserialport qt.qt6.683.addons.qtconnectivity qt.qt6.683.addons.qtpositioning extensions.qtwebengine.683 qt.qt6.683.addons.qtwebview qt.qt6.683.addons.qtwebchannel
ENV PATH="/qt/6.8.3/gcc_64/bin/:$PATH"

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

FROM base AS kdsa
COPY tools/buildkdsingleapplication.sh tools/
RUN tools/buildkdsingleapplication.sh

FROM base AS libserialport
COPY tools/buildlibserialport.sh tools/buildlibserialport.sh tools/
RUN tools/buildlibserialport.sh --disable-shared

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
