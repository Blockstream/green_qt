FROM ubuntu:18.04@sha256:3235326357dfb65f1781dbc4df3b834546d8bf914e82cce58e6e6b676e23ce8f

COPY tools/qtversion.env /
COPY tools/bionic_deps.sh /

COPY tools/builddeps.sh /tools/
COPY tools/buildgdk.sh /tools/
COPY tools/buildqt.sh /tools/
COPY tools/envs.env /tools/
COPY Dockerfile /

RUN /bionic_deps.sh && /tools/builddeps.sh linux && /tools/builddeps.sh windows && rm -fr /qt-everywhere-src-*
