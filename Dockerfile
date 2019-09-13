FROM ubuntu:18.04@sha256:d1d454df0f579c6be4d8161d227462d69e163a8ff9d20a847533989cf0c94d90
COPY tools/bionic_deps.sh /
RUN /bionic_deps.sh
