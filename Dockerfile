FROM ubuntu:18.04@sha256:bec5a2727be7fff3d308193cfde3491f8fba1a2ba392b7546b43a051853a341d
COPY tools/qtversion.env /
COPY tools/bionic_deps.sh /
RUN /bionic_deps.sh
