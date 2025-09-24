include(FindPackageHandleStandardArgs)

find_path(COUNTLY_INCLUDE_DIR countly/countly.hpp)
find_library(COUNTLY_LIBRARY NAMES libcountly.a countly.lib)

find_package_handle_standard_args(Countly
  REQUIRED_VARS COUNTLY_INCLUDE_DIR COUNTLY_LIBRARY
)

if(Countly_FOUND)
  mark_as_advanced(COUNTLY_INCLUDE_DIR)
  mark_as_advanced(COUNTLY_LIBRARY)
endif()

if(Countly_FOUND AND NOT TARGET Countly::SDK)
  add_library(Countly::SDK STATIC IMPORTED)
  set_target_properties(Countly::SDK PROPERTIES
    IMPORTED_LOCATION "${COUNTLY_LIBRARY}"
    INTERFACE_INCLUDE_DIRECTORIES "${COUNTLY_INCLUDE_DIR}"
  )
endif()
