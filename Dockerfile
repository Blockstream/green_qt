FROM ubuntu:18.04@sha256:8d31dad0c58f552e890d68bbfb735588b6b820a46e459672d96e585871acc110
COPY tools/bionic_deps.sh /
RUN /bionic_deps.sh
