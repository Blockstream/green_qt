#!/bin/bash
set -eo pipefail

GDKVENV=${GDK_PATH}/venv

if [ -f ${GDK_PATH}/build.done ]; then
    exit 0
fi

echo "GDK: building with ${NUM_JOBS} cores in ${GDK_PATH}"

mkdir -p ${GDK_PATH}

if [ ! -d "${GDK_PATH}/src" ]; then
    git clone --quiet --depth 1 --branch ${GDKTAG} --single-branch https://github.com/Blockstream/gdk.git ${GDK_PATH}/src > ${GDK_PATH}/build.log 2>&1
fi

cd ${GDK_PATH}/src

# unset to disable building gdk java support
unset JAVA_HOME

if [ ! -f ${GDKVENV}/build.done ]; then
    virtualenv -p python3 ${GDKVENV} >> ${GDK_PATH}/build.log 2>&1
    source ${GDKVENV}/bin/activate >> ${GDK_PATH}/build.log 2>&1
    pip install -r tools/requirements.txt >> ${GDK_PATH}/build.log 2>&1
    touch ${GDKVENV}/build.done
fi

source ${GDKVENV}/bin/activate >> ${GDK_PATH}/build.log 2>&1
if [ "$GREENPLATFORM" = "linux" ]; then
    tools/build.sh --gcc >> ${GDK_PATH}/build.log 2>&1
elif [ "$GREENPLATFORM" = "windows" ]; then
    tools/build.sh --mingw-w64 >> ${GDK_PATH}/build.log 2>&1
elif [ "$GREENPLATFORM" = "osx" ]; then
    unset JAVA_HOME
    tools/build.sh --clang >> ${GDK_PATH}/build.log 2>&1
else
    exit 1
fi

echo "GDK: copying files"

cp -R  ${GDK_PATH}/src/build-*/src/libgreenaddress* ${GDK_PATH}
cp -R  ${GDK_PATH}/src/build-*/external_deps_build/libwally-core/build/include/* ${GDK_PATH}
cp -R  ${GDK_PATH}/src/build-*/external_deps_build/boost/build/lib/libboost_log.a ${GDK_PATH}
cp -R  ${GDK_PATH}/src/build-*/external_deps_build/nlohmann_json/include/nlohmann ${GDK_PATH}
cp -R  ${GDK_PATH}/src/build-*/external_deps_build/boost/build/include/boost ${GDK_PATH}
cp -R  ${GDK_PATH}/src/include/*.h ${GDK_PATH}

rm -fr ${GDK_PATH}/src ${GDKVENV}

touch ${GDK_PATH}/build.done
