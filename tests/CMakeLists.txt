include(CTest)
find_package(Qt6 6.11 COMPONENTS Test REQUIRED)

add_subdirectory(unit)
add_subdirectory(qml)
