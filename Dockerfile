FROM debian:buster@sha256:2f04d3d33b6027bb74ecc81397abe780649ec89f1a2af18d7022737d0482cefe
COPY tools/buster_deps.sh /
RUN /buster_deps.sh
