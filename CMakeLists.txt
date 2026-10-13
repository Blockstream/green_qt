cmake_minimum_required(VERSION 3.16)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")
include(cmake/ProjectMeta.cmake)

project(${BLOCKSTREAM_PROJECT_NAME}
    VERSION "${BLOCKSTREAM_VERSION}"
    DESCRIPTION "${BLOCKSTREAM_DESCRIPTION}"
    HOMEPAGE_URL "${BLOCKSTREAM_HOMEPAGE_URL}"
    LANGUAGES CXX
)
include(CTest)

include(GNUInstallDirs)

include(cmake/AppOptions.cmake)
include(cmake/AppDependencies.cmake)
include(cmake/PlatformConfig.cmake)

qt_add_library(blockstream_core STATIC)

add_subdirectory(src)
add_subdirectory(app)

include(cmake/AppLib.cmake)

add_subdirectory(modules)
add_subdirectory(qml)
include(cmake/QmlModule.cmake)

add_subdirectory(assets)
add_subdirectory(i18n)
if(BUILD_TESTING)
    add_subdirectory(tests)
endif()
