FROM ubuntu:bionic
COPY ci/linux-x86_64/bionic.sh .
RUN ./bionic.sh
ENV PREFIX=/depends/linux-x86_64
ENV HOST=linux
ENV ARCH=x86_64
ENV PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig
ENV CMAKE_INSTALL_PREFIX=$PREFIX
COPY tools tools
RUN . /root/.cargo/env && tools/builddeps.sh