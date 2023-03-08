cmake_minimum_required(VERSION 3.16)

project(green VERSION 1.2.0 LANGUAGES CXX)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Debug)
endif()

if(NOT GREEN_ENV)
    set(GREEN_ENV Development)
    set(GREEN_BUILD_ID -dev)
    set(GREEN_LOG_FILE dev)
endif()

configure_file(config.h.in config.h @ONLY)

find_package(Qt6 6.4 COMPONENTS Concurrent Quick QuickControls2 Widgets QuickWidgets Xml Core5Compat Bluetooth SerialPort LinguistTools Multimedia REQUIRED)
find_package(hidapi REQUIRED)

find_library(GDK_LIB NAMES libgreenaddress_full.a REQUIRED)
find_library(COUNTLY_LIB NAMES libcountly.a REQUIRED)

find_path(GDK_INC gdk.h)

set(CMAKE_FIND_LIBRARY_SUFFIXES ".a")

if (WIN32)
    find_library(HID_LIB NAMES libhid.a REQUIRED)
    set(CMAKE_EXE_LINKER_FLAGS "-static -static-libgcc -static-libstdc++ -fstack-protector")
elseif (APPLE)
    find_library(SECURITY Security REQUIRED)
elseif (UNIX)
    set(CMAKE_EXE_LINKER_FLAGS "-static-libgcc -static-libstdc++ -fstack-protector -Wl,--wrap=__divmoddi4 -Wl,--wrap=log2f")
endif()

set(CMAKE_AUTOMOC ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_definitions(-DNO_ICONV)

SET(QZXING_MULTIMEDIA ON)
SET(QZXING_USE_DECODER_1D_BARCODES ON)
SET(QZXING_USE_DECODER_QR_CODE ON)
SET(QZXING_USE_ENCODER ON)

add_subdirectory(ext/qzxing/src)

include(src.cmake)

set(app_icon_macos "${CMAKE_CURRENT_SOURCE_DIR}/assets/icons/green.icns")
set_source_files_properties(${app_icon_macos} PROPERTIES MACOSX_PACKAGE_LOCATION "Resources")

qt_add_executable(green WIN32 MACOSX_BUNDLE
    ${TARGET_SOURCES}
    ${app_icon_macos}
)

set_target_properties(green PROPERTIES
    MACOSX_BUNDLE_INFO_PLIST ${CMAKE_SOURCE_DIR}/Info.plist.in
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
    LINK_SEARCH_START_STATIC ON
    LINK_SEARCH_END_STATIC ON
)

target_link_libraries(green
    PRIVATE
    qzxing
    ${GDK_LIB}
    ${COUNTLY_LIB}
    Qt6::Concurrent Qt6::Quick Qt6::QuickControls2 Qt6::Widgets Qt6::QuickWidgets Qt6::Xml Qt6::Core5Compat Qt6::Bluetooth Qt6::SerialPort Qt6::Multimedia
    ${SECURITY}
    hidapi::hidapi
    ${HID_LIB}
)

if (WIN32)
elseif (APPLE)
elseif (UNIX)
    target_link_libraries(green PRIVATE dl)
endif()

install(TARGETS green
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR})

target_include_directories(green PRIVATE
  src src/jade src/resolvers src/controllers src/ledger src/handlers
  ${GDK_INC}
  sa
  "${CMAKE_CURRENT_BINARY_DIR}"
)

include(qml.cmake)
include(assets.cmake)
include(translations.cmake)