from debian:buster-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV NAME=CodeSignTool
ENV VERSION=v1.3.2
ENV CODE_SIGN_TOOL_PATH=/$NAME-$VERSION
ENV PATH=$CODE_SIGN_TOOL_PATH:$PATH

RUN apt-get update && apt-get install -y --no-install-recommends curl openjdk-11-jre unzip

RUN curl -o archive.zip https://www.ssl.com/download/codesigntool-for-linux-and-macos/

RUN echo d909c62435c6edaac95ef3f314cbc8a5f89b248fedecd65428fe64352392ca11  archive.zip | sha256sum -c

RUN unzip archive.zip -d $CODE_SIGN_TOOL_PATH

RUN chmod +x $CODE_SIGN_TOOL_PATH/CodeSignTool.sh
