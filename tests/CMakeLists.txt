include(CTest)
find_package(Qt6 6.11 COMPONENTS Test REQUIRED)

add_subdirectory(unit)
add_subdirectory(qml)

add_test(NAME test_icon_catalog
    COMMAND "${CMAKE_COMMAND}" -P "${CMAKE_CURRENT_SOURCE_DIR}/check_icons.cmake"
)
