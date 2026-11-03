# Everything the app is made of, minus main() and the packaging. The executable
# and the test targets link this library, so its usage requirements are PUBLIC.

set_target_properties(blockstream_core PROPERTIES
    AUTOMOC ON
)

target_compile_features(blockstream_core PUBLIC cxx_std_20)

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
    ZXing::ZXing
    Countly::SDK
    libserialport::libserialport
    hidapi::hidapi
    KDAB::kdsingleapplication
    leveldb::leveldb
    libwally-core::libwally-core
    ${SECURITY}
    ${FFMPEG_LIBRARIES}
)

target_link_libraries(blockstream_core
    PUBLIC
    ${APP_QT_LIBS}
    ${APP_CORE_LIBS}
)

if(TARGET libgpgme::libgpgme)
  target_link_libraries(blockstream_core PUBLIC libgpgme::libgpgme)
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

    target_link_libraries(blockstream_core
        PUBLIC
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
    # INTERFACE, so every executable linking this library gets it.
    target_link_options(blockstream_core INTERFACE /FORCE:MULTIPLE)
    target_include_directories(blockstream_core PUBLIC
        "C:/depends/windows-x86_64/include/gdk"
    )
else()
    target_link_libraries(blockstream_core PUBLIC gdk::green_gdk_full)
endif()

if(ENABLE_SENTRY)
    target_compile_definitions(blockstream_core PUBLIC ENABLE_SENTRY)

    # sentry-native bundles its own crashpad backend; linking sentry::sentry
    # pulls in crashpad and the rest of its transitive dependencies.
    find_package(sentry CONFIG REQUIRED)
    target_link_libraries(blockstream_core PUBLIC sentry::sentry)
endif()

if (WIN32)
    # WindowsApp for the WinRT calls in jadebluetoothpairing_win.cpp.
    target_link_libraries(blockstream_core PUBLIC hid ntdll userenv bcrypt WindowsApp)
elseif (APPLE)
    find_library(LIBLWK lwk REQUIRED)
    find_library(LIBGLSDK glsdk REQUIRED)
    target_link_libraries(blockstream_core PUBLIC
      ${LIBLWK}
      ${LIBGLSDK}
      "-framework SystemConfiguration"
    )
elseif (UNIX)
    find_library(LIBLWK lwk REQUIRED)
    find_library(LIBGLSDK glsdk REQUIRED)
    target_link_libraries(blockstream_core PUBLIC dl Xrender cap ${LIBLWK} ${LIBGLSDK} Qt6::WaylandClient)
endif()

target_include_directories(blockstream_core PUBLIC
    ${CMAKE_SOURCE_DIR}/src
    ${CMAKE_SOURCE_DIR}/src/jade
    ${CMAKE_SOURCE_DIR}/src/controllers
    ${CMAKE_SOURCE_DIR}/src/ledger
    ${CMAKE_SOURCE_DIR}/src/glsdk
    ${CMAKE_SOURCE_DIR}/src/lightning
    ${CMAKE_SOURCE_DIR}/src/models
)
