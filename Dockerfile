FROM debian:buster
#FROM debian:stretch@sha256:72e996751fe42b2a0c1e6355730dc2751ccda50564fec929f76804a6365ef5ef
RUN echo hi

RUN apt update -qq
RUN apt upgrade --no-install-recommends -yqq

RUN apt install --no-install-recommends -yqq build-essential

RUN apt install --no-install-recommends -yqq clang curl ca-certificates unzip git automake autoconf pkg-config libtool virtualenv
#swig openjdk-8-jdk 

RUN apt install --no-install-recommends -yqq qt5-default qtdeclarative5-dev

RUN git clone --quiet --depth 1 --single-branch --branch release_0.0.19 https://github.com/Blockstream/gdk.git

RUN apt update -yqq

RUN apt install --no-install-recommends -yyq ninja-build llvm-dev python3-pip python3-setuptools python3-wheel #{pip,setuptools,wheel}

RUN pip3 install --require-hashes -r /gdk/tools/requirements.txt

WORKDIR /green


RUN apt install --no-install-recommends -yqq qtquickcontrols2-5-dev

RUN cd /gdk && alias python=python3 && tools/build.sh --clang

#COPY . ./
#RUN qmake && make
