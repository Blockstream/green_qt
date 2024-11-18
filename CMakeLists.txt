cmake_minimum_required(VERSION 3.16)

project(green VERSION 2.0.14 LANGUAGES CXX)

option(GREEN_WAYLAND "Include Wayland support" OFF)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Debug)
endif()

if(NOT GREEN_ENV)
    set(GREEN_ENV Development)
    set(GREEN_BUILD_ID -dev)
    set(GREEN_LOG_FILE dev)
endif()

configure_file(config.h.in config.h @ONLY)
configure_file(installer.iss.in installer.iss @ONLY)

find_package(Qt6 6.7 COMPONENTS Concurrent Quick QuickControls2 Widgets QuickWidgets Xml Core5Compat Bluetooth SerialPort LinguistTools Multimedia REQUIRED)

find_package(hidapi REQUIRED)
find_package(KDSingleApplication-qt6 CONFIG REQUIRED)

find_package(gdk REQUIRED COMPONENT green_gdk_full)

find_package(ZXing REQUIRED)

include(CMakePrintHelpers)
cmake_print_properties(TARGETS gdk::green_gdk_full PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES
    INTERFACE_LINK_LIBRARIES
    IMPORTED_LOCATION_RELEASE
)

find_library(COUNTLY_LIB NAMES libcountly.a REQUIRED)
find_library(LIBSERIALPORT_LIB NAMES libserialport.a REQUIRED)

set(CMAKE_FIND_LIBRARY_SUFFIXES ".a")

if (WIN32)
    find_library(HID_LIB NAMES libhid.a REQUIRED)
    set(CMAKE_EXE_LINKER_FLAGS "-static -static-libgcc -static-libstdc++ -fstack-protector")
elseif (APPLE)
    find_library(SECURITY Security REQUIRED)
elseif (UNIX)
    if (GREEN_WAYLAND)
        find_package(Qt6 6.4 COMPONENTS WaylandClient REQUIRED)
    endif()
    set(CMAKE_EXE_LINKER_FLAGS "-static-libgcc -static-libstdc++ -fstack-protector -Wl,--wrap=__divmoddi4 -Wl,--wrap=log2f")
endif()

set(CMAKE_AUTOMOC ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_definitions(-DNO_ICONV)
add_definitions(-DGDK_STATIC_DEFINE)

include(src.cmake)

set(app_icon_macos "${CMAKE_CURRENT_SOURCE_DIR}/assets/icons/green.icns")
set_source_files_properties(${app_icon_macos} PROPERTIES MACOSX_PACKAGE_LOCATION "Resources")

if (${CMAKE_SYSTEM_NAME} MATCHES "Windows")
    enable_language("RC")
    set(app_icon_win "${CMAKE_CURRENT_SOURCE_DIR}/green.rc")
endif()

qt_add_executable(green WIN32 MACOSX_BUNDLE
    ${TARGET_SOURCES}
    ${app_icon_macos}
    ${app_icon_win}
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
    ZXing::Core
    gdk::green_gdk_full
    ${COUNTLY_LIB}
    ${LIBSERIALPORT_LIB}
    Qt6::Concurrent Qt6::Quick Qt6::QuickControls2 Qt6::Widgets Qt6::QuickWidgets Qt6::Xml Qt6::Core5Compat Qt6::Bluetooth Qt6::SerialPort Qt6::Multimedia
    ${SECURITY}
    hidapi::hidapi
    ${HID_LIB}
    KDAB::kdsingleapplication
)

if (WIN32)
elseif (APPLE)
    set_target_properties(green PROPERTIES OUTPUT_NAME "Blockstream Green")
elseif (UNIX)
    target_link_libraries(green PRIVATE dl)
    qt_import_plugins(green INCLUDE Qt6::QXcbIntegrationPlugin)
    if (GREEN_WAYLAND)
        target_link_libraries(green PRIVATE Qt6::WaylandClient)
        qt_import_plugins(green INCLUDE Qt6::QWaylandIntegrationPlugin)
    endif()
endif()

install(TARGETS green
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR})

get_target_property(GDK_INCLUDE gdk::green_gdk_full INTERFACE_INCLUDE_DIRECTORIES)

target_include_directories(green PRIVATE
  src src/jade src/resolvers src/controllers src/ledger src/handlers
  ${GDK_INCLUDE}/libwally-core/
  "${CMAKE_CURRENT_BINARY_DIR}"
)

include(qml.cmake)
include(assets.cmake)
include(translations.cmake)
