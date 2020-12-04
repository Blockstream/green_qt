FROM ubuntu:18.04@sha256:fd25e706f3dea2a5ff705dbc3353cf37f08307798f3e360a13e9385840f73fb3

COPY tools/qtversion.env /
COPY tools/bionic_deps.sh /

COPY tools/builddeps.sh /tools/
COPY tools/buildgdk.sh /tools/
COPY tools/buildqt.sh /tools/
COPY tools/envs.env /tools/

RUN /bionic_deps.sh && /tools/builddeps.sh linux && /tools/builddeps.sh windows && rm -fr /qt-everywhere-src-*
