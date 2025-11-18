cmake_minimum_required(VERSION 3.16)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")

project(blockstream VERSION 2.0.30 LANGUAGES CXX)

option(GREEN_WAYLAND "Include Wayland support" OFF)
option(ENABLE_SENTRY "Enable crash reports with sentry" OFF)

set(APP_TARGET blockstream)
set(CMAKE_AUTOMOC ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(NOT GREEN_ENV)
    set(CMAKE_BUILD_TYPE Debug)
    set(GREEN_ENV Development)
    set(GREEN_BUILD_ID -dev)
    set(GREEN_LOG_FILE dev)
endif()

configure_file(config.h.in config.h @ONLY)
configure_file(installer.iss.in installer.iss @ONLY)

find_package(Qt6 6.7 COMPONENTS Concurrent Quick QuickControls2 Widgets QuickWidgets Xml Core5Compat Bluetooth SerialPort LinguistTools Multimedia REQUIRED)
find_package(Countly REQUIRED)
find_package(hidapi REQUIRED)
find_package(KDSingleApplication-qt6 CONFIG REQUIRED)
find_package(libgpgme)
find_package(libserialport REQUIRED)
find_package(ZXing REQUIRED)

if (WIN32 AND NOT QT_FEATURE_static)
else()
    find_package(gdk REQUIRED COMPONENT green_gdk_full)
endif()

if (WIN32)
    #find_library(HID_LIB NAMES libhid.a REQUIRED)
    #set(CMAKE_EXE_LINKER_FLAGS "-static -static-libgcc -static-libstdc++ -fstack-protector")
elseif (APPLE)
    find_library(SECURITY Security REQUIRED)
elseif (UNIX)
    if (QT_FEATURE_static)
        find_library(AVCODEC NAMES libavcodec.a REQUIRED)
        find_library(AVDEVICE NAMES libavdevice.a REQUIRED)
        find_library(AVFILTER NAMES libavfilter.a REQUIRED)
        find_library(AVFORMAT NAMES libavformat.a REQUIRED)
        find_library(AVUTIL NAMES libavutil.a REQUIRED)
        find_library(SWSCALE NAMES libswscale.a REQUIRED)
        find_library(SWRESAMPLE NAMES libswresample.a REQUIRED)
        find_library(POSTPROC NAMES libpostproc.a REQUIRED)
        set(FFMPEG_LIBRARIES /depends/linux-x86_64/plugins/multimedia/libffmpegmediaplugin.a ${AVDEVICE} ${AVFILTER} ${AVFORMAT} ${AVCODEC} ${POSTPROC} ${SWRESAMPLE} ${SWSCALE} ${AVUTIL} Xrandr Xrender)
        message(STATUS "FFMPEG_LIBRARIES: ${FFMPEG_LIBRARIES}")
    endif()
    if (GREEN_WAYLAND)
        find_package(Qt6 6.4 COMPONENTS WaylandClient REQUIRED)
    endif()
    set(CMAKE_EXE_LINKER_FLAGS "-static-libgcc -static-libstdc++ -fstack-protector -Wl,--wrap=__divmoddi4 -Wl,--wrap=log2f")
endif()

# https://gitlab.kitware.com/cmake/cmake/issues/20256
if(APPLE)
  find_program(DSYMUTIL_PROGRAM dsymutil)
  if(DSYMUTIL_PROGRAM)
    foreach(lang C CXX)
      foreach(var LINK_EXECUTABLE CREATE_SHARED_LIBRARY)
        set(CMAKE_${lang}_${var} "${CMAKE_${lang}_${var}}" "${DSYMUTIL_PROGRAM} <TARGET>")
      endforeach()
    endforeach()
  endif()
endif()

include(src.cmake)

set(app_icon_macos "${CMAKE_CURRENT_SOURCE_DIR}/assets/icons/production.icns")
set_source_files_properties(${app_icon_macos} PROPERTIES MACOSX_PACKAGE_LOCATION "Resources")

if (${CMAKE_SYSTEM_NAME} MATCHES "Windows")
    enable_language("RC")
    set(app_icon_win "${CMAKE_CURRENT_SOURCE_DIR}/production.rc")
endif()

qt_add_executable(${APP_TARGET} WIN32 MACOSX_BUNDLE
    ${TARGET_SOURCES}
    ${app_icon_macos}
    ${app_icon_win}
)

set_target_properties(${APP_TARGET} PROPERTIES
    MACOSX_BUNDLE_INFO_PLIST ${CMAKE_SOURCE_DIR}/Info.plist.in
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
    LINK_SEARCH_START_STATIC ON
    LINK_SEARCH_END_STATIC ON
)

target_link_libraries(${APP_TARGET}
    PRIVATE
    ZXing::Core
    Countly::SDK
    libserialport::libserialport
    Qt6::Concurrent Qt6::Quick Qt6::QuickControls2 Qt6::Widgets Qt6::QuickWidgets Qt6::Xml Qt6::Core5Compat Qt6::Bluetooth Qt6::SerialPort Qt6::Multimedia
    ${SECURITY}
    hidapi::hidapi
    KDAB::kdsingleapplication
    ${FFMPEG_LIBRARIES}
)

if(TARGET libgpgme::libgpgme)
  target_link_libraries(${APP_TARGET} PRIVATE libgpgme::libgpgme)
endif()

if (WIN32 AND NOT QT_FEATURE_static)
    target_link_libraries(${APP_TARGET}
        PRIVATE
        "C:/depends/windows-x86_64/lib/libgreen_gdk.lib"
    )
    target_include_directories(${APP_TARGET} PRIVATE
        "C:/depends/windows-x86_64/include/gdk"
        "C:/depends/windows-x86_64/include/gdk/libwally-core"
    )
else()
    target_link_libraries(${APP_TARGET} PRIVATE gdk::green_gdk_full)
    get_target_property(GDK_INCLUDE gdk::green_gdk_full INTERFACE_INCLUDE_DIRECTORIES)
    target_include_directories(${APP_TARGET} PRIVATE ${GDK_INCLUDE}/libwally-core/)
endif()

if(ENABLE_SENTRY)
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(BREAKPAD REQUIRED breakpad)

    find_library(LIBBREAKPAD_LIB NAMES libbreakpad.a REQUIRED)
    find_library(LIBDISASM_LIB NAMES libdisasm.a REQUIRED)

    add_compile_definitions(ENABLE_SENTRY)

    if (UNIX AND NOT APPLE)
      find_package(CURL REQUIRED)
    endif()

    find_package(crashpad REQUIRED)

    get_target_property(CRASHPAD_INCLUDE crashpad::client INTERFACE_INCLUDE_DIRECTORIES)

    target_include_directories(${APP_TARGET} PRIVATE
      ${CRASHPAD_INCLUDE}
      ${CRASHPAD_INCLUDE}/..
      ${BREAKPAD_INCLUDE_DIRS}
    )
    target_link_libraries(${APP_TARGET} PRIVATE
        crashpad::client
        crashpad::handler
        crashpad::minidump
        crashpad::snapshot
        crashpad::tools
        crashpad::util
        crashpad::zlib
        ${LIBBREAKPAD_LIB} ${LIBDISASM_LIB}
    )

    # Avoid linking to llvm@16 libunwind.1.dylib
    if (APPLE)
        find_library(LIBUNWIND_LIB NAMES libunwind.a)
        if (LIBUNWIND_LIB)
            target_link_libraries(${APP_TARGET} PRIVATE ${LIBUNWIND_LIB})
        endif()
    endif()
endif()

if (WIN32)
    target_link_libraries(${APP_TARGET} PRIVATE hid ntdll)
elseif (APPLE)
    set_target_properties(${APP_TARGET} PROPERTIES OUTPUT_NAME "Blockstream")
elseif (UNIX)
    target_link_libraries(${APP_TARGET} PRIVATE dl Xrender)
    qt_import_plugins(${APP_TARGET} INCLUDE Qt6::QXcbIntegrationPlugin Qt6::QFFmpegMediaPlugin)
    if (GREEN_WAYLAND)
        target_link_libraries(${APP_TARGET} PRIVATE Qt6::WaylandClient Xrender)
        qt_import_plugins(${APP_TARGET} INCLUDE Qt6::QWaylandIntegrationPlugin Qt6::QFFmpegMediaPlugin)
    endif()
endif()

install(TARGETS ${APP_TARGET}
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR})

target_include_directories(${APP_TARGET} PRIVATE
  src src/jade src/resolvers src/controllers src/ledger src/handlers
  "${CMAKE_CURRENT_BINARY_DIR}"
)

target_include_directories(${APP_TARGET} PRIVATE
  src src/jade src/resolvers src/controllers src/ledger src/handlers
  ${GDK_INCLUDE}/libwally-core/
  "${CMAKE_CURRENT_BINARY_DIR}"
)

include(qml.cmake)
include(assets.cmake)
include(translations.cmake)
