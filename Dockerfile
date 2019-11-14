FROM ubuntu:18.04@sha256:6e9f67fa63b0323e9a1e587fd71c561ba48a034504fb804fd26fd8800039835d
COPY tools/bionic_deps.sh /
RUN /bionic_deps.sh
