option(ENABLE_SENTRY "Enable crash reports with sentry" OFF)

set(APP_TARGET blockstream)

message(STATUS "CMAKE_BUILD_TYPE = ${CMAKE_BUILD_TYPE}")
message(STATUS "GREEN_ENV = ${GREEN_ENV}")
message(STATUS "GREEN_BUILD_ID = ${GREEN_BUILD_ID}")
message(STATUS "GREEN_LOG_FILE = ${GREEN_LOG_FILE}")

if(NOT GREEN_ENV)
    set(CMAKE_BUILD_TYPE Debug)
    set(GREEN_ENV Development)
    set(GREEN_BUILD_ID -dev)
    set(GREEN_LOG_FILE dev)
endif()

configure_file("${CMAKE_SOURCE_DIR}/installer.iss.in" "${CMAKE_BINARY_DIR}/installer.iss" @ONLY)

