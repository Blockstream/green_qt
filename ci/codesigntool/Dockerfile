FROM debian:stable-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV NAME=CodeSignTool
ENV VERSION=v1.3.3
ENV CODE_SIGN_TOOL_PATH=/$NAME-$VERSION
ENV PATH=$CODE_SIGN_TOOL_PATH:$PATH

RUN apt-get update && apt-get install -y --no-install-recommends curl openjdk-21-jre unzip

RUN curl -o archive.zip https://www.ssl.com/download/codesigntool-for-linux-and-macos/

RUN echo ecdb16fb60c9be1145f450924b8b1e615bee08ac45180d5f66b47712a223a6ec  archive.zip | sha256sum -c

RUN unzip archive.zip -d $CODE_SIGN_TOOL_PATH

RUN chmod +x $CODE_SIGN_TOOL_PATH/CodeSignTool.sh
