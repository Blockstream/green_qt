configure_file(config.h.in "${CMAKE_CURRENT_BINARY_DIR}/config.h" @ONLY)

add_library(blockstream_core STATIC
    profile.h profile.cpp
    util.h util.cpp
)

target_include_directories(blockstream_core PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_BINARY_DIR}
)

target_link_libraries(blockstream_core PUBLIC Qt6::Core)
