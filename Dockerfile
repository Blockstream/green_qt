FROM ubuntu:18.04@sha256:86510528ab9cd7b64209cbbe6946e094a6d10c6db21def64a93ebdd20011de1d

COPY tools/qtversion.env /
COPY tools/bionic_deps.sh /

COPY tools/builddeps.sh /tools/
COPY tools/buildgdk.sh /tools/
COPY tools/buildqt.sh /tools/
COPY tools/envs.env /tools/

RUN /bionic_deps.sh && /tools/builddeps.sh linux && /tools/builddeps.sh windows && rm -fr /qt-everywhere-src-*
