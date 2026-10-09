add_test(NAME test_icon_catalog
    COMMAND "${CMAKE_COMMAND}" -P "${CMAKE_CURRENT_SOURCE_DIR}/check_icons.cmake"
)
