from debian:buster-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV NAME=CodeSignTool
ENV VERSION=v1.2.7
ENV CODE_SIGN_TOOL_PATH=/$NAME-$VERSION
ENV PATH=$CODE_SIGN_TOOL_PATH:$PATH

RUN apt-get update && apt-get install -y --no-install-recommends curl openjdk-11-jre unzip

RUN curl -o archive.zip https://www.ssl.com/download/codesigntool-for-linux-and-macos/

RUN echo ad3e389eca2367a33608c0678c3bf4e274143f583eb655859b76d0e680e8accc  archive.zip | sha256sum -c

RUN unzip archive.zip

RUN chmod +x $CODE_SIGN_TOOL_PATH/CodeSignTool.sh
