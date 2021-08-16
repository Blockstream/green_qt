#!/bin/bash
set -eo pipefail

source ../../version.pri

VERSION=${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}

cp ../../tools/win_installer_template.iss win_installer.iss
sed -i -e "s/VERSION_STRING/${VERSION}/g" win_installer.iss

echo ${VERSION}

iscc win_installer.iss
