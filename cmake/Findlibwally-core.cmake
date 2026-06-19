include(FindPackageHandleStandardArgs)

# The libwally-core headers ship inside the gdk install tree under
# gdk/libwally-core. The wally symbols themselves are bundled into the gdk
# static library (gdk::green_gdk_full / libgreen_gdk), so this package only
# provides the header search path and is consumed as a header-only target.
find_path(LIBWALLYCORE_INCLUDE_DIR
  NAMES wally_core.h
  PATH_SUFFIXES gdk/libwally-core libwally-core
)

find_package_handle_standard_args(libwally-core
  REQUIRED_VARS LIBWALLYCORE_INCLUDE_DIR
)

if(libwally-core_FOUND)
  mark_as_advanced(LIBWALLYCORE_INCLUDE_DIR)
endif()

if(libwally-core_FOUND AND NOT TARGET libwally-core::libwally-core)
  add_library(libwally-core::libwally-core INTERFACE IMPORTED)
  set_target_properties(libwally-core::libwally-core PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${LIBWALLYCORE_INCLUDE_DIR}"
  )
endif()
