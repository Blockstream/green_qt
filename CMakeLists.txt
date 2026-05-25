cmake_minimum_required(VERSION 3.16)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")
include(cmake/ProjectMeta.cmake)

project(blockstream VERSION 3.4.0 LANGUAGES CXX)
include(CTest)

include(GNUInstallDirs)

include(cmake/AppOptions.cmake)
include(cmake/AppDependencies.cmake)
include(cmake/PlatformConfig.cmake)

qt_add_executable(${APP_TARGET} WIN32 MACOSX_BUNDLE)

add_subdirectory(src)
include(cmake/AppTarget.cmake)

add_subdirectory(qml)
include(cmake/QmlModule.cmake)

add_subdirectory(assets)
add_subdirectory(i18n)
if(BUILD_TESTING)
    add_subdirectory(tests)
endif()
