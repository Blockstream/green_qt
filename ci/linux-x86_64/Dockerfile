FROM ubuntu:bionic AS base
COPY ci/linux-x86_64/bionic.sh .
RUN ./bionic.sh
ENV PREFIX=/depends/linux-x86_64
ENV HOST=linux
ENV ARCH=x86_64
ENV PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig
ENV CMAKE_INSTALL_PREFIX=$PREFIX
COPY tools tools

FROM base AS builder
RUN . /root/.cargo/env && tools/builddeps.sh

FROM base
COPY --from=builder /depends /depends
