find_library(SECURITY Security REQUIRED)

# Apply warning to all targets in the project.
set_property(DIRECTORY "${CMAKE_SOURCE_DIR}" APPEND PROPERTY COMPILE_OPTIONS -Wno-elaborated-enum-base)

# https://gitlab.kitware.com/cmake/cmake/issues/20256
find_program(DSYMUTIL_PROGRAM dsymutil)
if(DSYMUTIL_PROGRAM)
  foreach(lang C CXX)
    foreach(var LINK_EXECUTABLE CREATE_SHARED_LIBRARY)
      set(CMAKE_${lang}_${var} "${CMAKE_${lang}_${var}}" "${DSYMUTIL_PROGRAM} <TARGET>")
    endforeach()
  endforeach()
endif()

