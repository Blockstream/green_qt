include(FindPackageHandleStandardArgs)

find_library(LIBGPGME_LIBRARY NAMES libgpgme.a)
find_library(LIBASSUAN_LIBRARY NAMES libassuan.a)
find_library(LIBGPGERROR_LIBRARY NAMES libgpg-error.a)

find_package_handle_standard_args(libgpgme
  REQUIRED_VARS LIBGPGME_LIBRARY LIBASSUAN_LIBRARY LIBGPGERROR_LIBRARY
)

if(libgpgme_FOUND)
  mark_as_advanced(LIBGPGME_LIBRARY)
  mark_as_advanced(LIBASSUAN_LIBRARY)
  mark_as_advanced(LIBGPGERROR_LIBRARY)
endif()

if(libgpgme_FOUND AND NOT TARGET libgpgme::libgpgme)
  add_library(libgpgme::libgpgme UNKNOWN IMPORTED)
  set_target_properties(libgpgme::libgpgme PROPERTIES
    IMPORTED_LOCATION "${LIBGPGME_LIBRARY}"
    INTERFACE_LINK_LIBRARIES "${LIBASSUAN_LIBRARY};${LIBGPGERROR_LIBRARY}"
  )
endif()
