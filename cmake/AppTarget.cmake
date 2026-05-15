set(app_icon_macos "${CMAKE_SOURCE_DIR}/assets/icons/production.icns")
set_source_files_properties(${app_icon_macos} PROPERTIES MACOSX_PACKAGE_LOCATION "Resources")
target_sources(${APP_TARGET} PRIVATE ${app_icon_macos})
target_compile_features(${APP_TARGET} PRIVATE cxx_std_20)

if (WIN32)
    enable_language("RC")
    set(app_icon_win "${CMAKE_SOURCE_DIR}/production.rc")
    target_sources(${APP_TARGET} PRIVATE ${app_icon_win})
endif()

set_target_properties(${APP_TARGET} PROPERTIES
    AUTOMOC ON
    LINK_SEARCH_START_STATIC ON
    LINK_SEARCH_END_STATIC ON
)

if(APPLE)
    set_target_properties(${APP_TARGET} PROPERTIES
        MACOSX_BUNDLE_INFO_PLIST ${CMAKE_SOURCE_DIR}/Info.plist.in
        MACOSX_BUNDLE TRUE
    )
endif()

if(WIN32)
    set_target_properties(${APP_TARGET} PROPERTIES
        WIN32_EXECUTABLE TRUE
    )
endif()

set(APP_QT_LIBS
    Qt6::Concurrent
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Widgets
    Qt6::QuickWidgets
    Qt6::Xml
    Qt6::Core5Compat
    Qt6::Bluetooth
    Qt6::SerialPort
    Qt6::Multimedia
    Qt6::WebEngineQuick
)

set(APP_CORE_LIBS
    ZXing::Core
    Countly::SDK
    libserialport::libserialport
    hidapi::hidapi
    KDAB::kdsingleapplication
    leveldb::leveldb
    ${SECURITY}
    ${FFMPEG_LIBRARIES}
)

target_link_libraries(${APP_TARGET}
    PRIVATE
    ${APP_QT_LIBS}
    ${APP_CORE_LIBS}
)

if(TARGET libgpgme::libgpgme)
  target_link_libraries(${APP_TARGET} PRIVATE libgpgme::libgpgme)
endif()

if (WIN32 AND NOT QT_FEATURE_static)
    # lwk and glsdk are built natively in the MSVC container as a static library
    # and installed into CMAKE_PREFIX_PATH (C:/deps). gdk is still cross-built.
    find_library(LIBLWK lwk REQUIRED)
    find_library(LIBGLSDK glsdk REQUIRED)

    # The windows.<ver>.lib umbrella import libs come from the Rust windows-targets crate
    # (not the Windows SDK); lwk.bat copies them next to lwk.lib. Glob them by full path so
    # we don't hardcode the version (it tracks the pinned lwk commit's deps).
    get_filename_component(LWK_LIBDIR ${LIBLWK} DIRECTORY)
    get_filename_component(LIBGLSDK_DIR ${LIBGLSDK} DIRECTORY)

    file(GLOB LWK_WINDOWS_IMPORT_LIBS "${LWK_LIBDIR}/windows.*.lib")
    file(GLOB GLSDK_WINDOWS_IMPORT_LIBS "${LIBGLSDK_DIR}/windows.*.lib")

    target_link_libraries(${APP_TARGET}
        PRIVATE
        "C:/depends/windows-x86_64/lib/libgreen_gdk.lib"
        ${LIBLWK}
        ${LIBGLSDK}
        ${LWK_WINDOWS_IMPORT_LIBS}
        ${GLSDK_WINDOWS_IMPORT_LIBS}
        # Native system libs required to statically link lwk.lib. Source of truth is the
        # "native-static-libs:" line printed by ci/x64-windows/lwk.bat; keep in sync.
        # (kernel32/user32/advapi32 are MSVC defaults and msvcrt matches /MD, but listed
        # explicitly for clarity/robustness; ntdll is also added in the WIN32 block below.)
        advapi32 bcrypt cfgmgr32 dbghelp kernel32 ntdll user32 userenv ws2_32
    )
    # Use /FORCE:MULTIPLE to allow LWK and GLSDK to be linked together,
    # since they both link to some of the same system libs (e.g. ntdll).
    target_link_options(${APP_TARGET} PRIVATE /FORCE:MULTIPLE)
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

    target_compile_definitions(${APP_TARGET} PRIVATE ENABLE_SENTRY)

    if (UNIX AND NOT APPLE)
      find_package(CURL REQUIRED)
    endif()

    find_package(crashpad CONFIG REQUIRED)

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
    target_link_libraries(${APP_TARGET} PRIVATE hid ntdll userenv bcrypt)
elseif (APPLE)
    find_library(LIBLWK lwk REQUIRED)
    find_library(LIBGLSDK glsdk REQUIRED)
    target_link_libraries(${APP_TARGET} PRIVATE
      ${LIBLWK}
      ${LIBGLSDK}
      "-framework SystemConfiguration"
    )
    set_target_properties(${APP_TARGET} PROPERTIES OUTPUT_NAME "Blockstream")
elseif (UNIX)
    target_link_options(${APP_TARGET} PRIVATE
        -static-libgcc
        -static-libstdc++
        -fstack-protector
        -Wl,--wrap=__divmoddi4
        -Wl,--wrap=log2f
    )
    find_library(LIBLWK lwk REQUIRED)
    find_library(LIBGLSDK glsdk REQUIRED)
    target_link_libraries(${APP_TARGET} PRIVATE dl Xrender cap ${LIBLWK} ${LIBGLSDK} Qt6::WaylandClient)
    qt_import_plugins(${APP_TARGET} INCLUDE Qt6::QXcbIntegrationPlugin Qt6::QWaylandIntegrationPlugin Qt6::QFFmpegMediaPlugin)
endif()

set(APP_PRIVATE_INCLUDE_DIRS
    src
    src/jade
    src/resolvers
    src/controllers
    src/ledger
    src/handlers
    src/glsdk
    "${CMAKE_BINARY_DIR}"
)

if (GDK_INCLUDE)
    list(APPEND APP_PRIVATE_INCLUDE_DIRS ${GDK_INCLUDE}/libwally-core/)
endif()

target_include_directories(${APP_TARGET} PRIVATE ${APP_PRIVATE_INCLUDE_DIRS})

install(TARGETS ${APP_TARGET}
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR})
