add_subdirectory(theme)
add_subdirectory(controls)

if(NOT GREEN_ENV STREQUAL "Production")
    add_subdirectory(design-system)
endif()
