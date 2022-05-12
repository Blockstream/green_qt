FROM ubuntu:18.04@sha256:971a12d7e92a23183dead8bfc415aa650e7deb1cc5fed11a3d21f759a891fde9

COPY tools/qtversion.env /
COPY tools/bionic_deps.sh /
COPY tools /tools/

RUN /bionic_deps.sh && /tools/builddeps.sh linux && /tools/builddeps.sh windows && rm -fr /qt-everywhere-src-*
