option(ENABLE_SENTRY "Enable crash reports with sentry" OFF)

if(ENABLE_SENTRY AND (NOT SENTRY_KEY OR NOT SENTRY_PROJECT))
    message(FATAL_ERROR "ENABLE_SENTRY is ON but SENTRY_KEY/SENTRY_PROJECT is missing or empty")
endif()

set(APP_TARGET ${BLOCKSTREAM_PROJECT_NAME})

message(STATUS "PROJECT_NAME = ${PROJECT_NAME}")
message(STATUS "PROJECT_VERSION = ${PROJECT_VERSION}")
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
