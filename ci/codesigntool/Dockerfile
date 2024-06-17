from debian:buster-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV NAME=CodeSignTool
ENV VERSION=v1.3.0
ENV CODE_SIGN_TOOL_PATH=/$NAME-$VERSION
ENV PATH=$CODE_SIGN_TOOL_PATH:$PATH

RUN apt-get update && apt-get install -y --no-install-recommends curl openjdk-11-jre unzip

RUN curl -o archive.zip https://www.ssl.com/download/codesigntool-for-linux-and-macos/

RUN echo 83d72ca2f0cf9a61ec7f2b0470e91abfdb5999392170097f0f4d81cbea4a5458  archive.zip | sha256sum -c

RUN unzip archive.zip -d $CODE_SIGN_TOOL_PATH

RUN chmod +x $CODE_SIGN_TOOL_PATH/CodeSignTool.sh
