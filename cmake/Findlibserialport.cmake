include(FindPackageHandleStandardArgs)

find_path(LIBSERIALPORT_INCLUDE_DIR libserialport.h)

if(MSVC)
  find_library(LIBSERIALPORT_LIBRARY NAMES libserialport-0.lib)
else()
  find_library(LIBSERIALPORT_LIBRARY NAMES libserialport.a)
endif()

find_package_handle_standard_args(libserialport
  REQUIRED_VARS LIBSERIALPORT_LIBRARY LIBSERIALPORT_INCLUDE_DIR
)

if(libserialport_FOUND)
  mark_as_advanced(LIBSERIALPORT_INCLUDE_DIR)
  mark_as_advanced(LIBSERIALPORT_LIBRARY)
endif()

if(libserialport_FOUND AND NOT TARGET libserialport::libserialport)
  add_library(libserialport::libserialport UNKNOWN IMPORTED)
  set_target_properties(libserialport::libserialport PROPERTIES
    IMPORTED_LOCATION "${LIBSERIALPORT_LIBRARY}"
    INTERFACE_INCLUDE_DIRECTORIES "${LIBSERIALPORT_INCLUDE_DIR}"
  )
endif()
