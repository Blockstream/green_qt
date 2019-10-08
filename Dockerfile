FROM ubuntu:18.04@sha256:b88f8848e9a1a4e4558ba7cfc4acc5879e1d0e7ac06401409062ad2627e6fb58
COPY tools/bionic_deps.sh /
RUN /bionic_deps.sh
