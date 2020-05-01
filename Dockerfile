FROM ubuntu:18.04@sha256:3235326357dfb65f1781dbc4df3b834546d8bf914e82cce58e6e6b676e23ce8f
COPY tools/qtversion.env /
COPY tools/bionic_deps.sh /
RUN /bionic_deps.sh
