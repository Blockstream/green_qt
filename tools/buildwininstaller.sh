#!/bin/bash
set -eo pipefail

MAJOR=`cat ../../version.pri | grep VERSION_MAJOR`
MAJOR="${MAJOR: -1}"

MINOR=`cat ../../version.pri | grep VERSION_MINOR`
MINOR="${MINOR: -1}"

PATCH=`cat ../../version.pri | grep VERSION_PATCH`
PATCH="${PATCH: -1}"

VERSION=$MAJOR.$MINOR.$PATCH

cp ../../tools/win_installer_template.iss win_installer.iss
sed -i -e "s/VERSION_STRING/${VERSION}/g" win_installer.iss

echo ${VERSION}

iscc win_installer.iss
