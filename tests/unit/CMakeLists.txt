set(TEST_TARGET test_smoke)

qt_add_executable(${TEST_TARGET}
    tst_smoke.cpp
)

set_target_properties(${TEST_TARGET} PROPERTIES
    AUTOMOC ON
)

target_link_libraries(${TEST_TARGET}
    PRIVATE
    Qt6::Core
    Qt6::Test
)

add_test(NAME ${TEST_TARGET} COMMAND ${TEST_TARGET})

set(LNURL_TEST_TARGET test_lightninglnurl)

qt_add_executable(${LNURL_TEST_TARGET}
    tst_lightninglnurl.cpp
    ${CMAKE_SOURCE_DIR}/src/lightning/lightninglnurl.cpp
)

set_target_properties(${LNURL_TEST_TARGET} PROPERTIES
    AUTOMOC ON
)

target_include_directories(${LNURL_TEST_TARGET} PRIVATE
    ${CMAKE_SOURCE_DIR}/src/lightning
)

target_link_libraries(${LNURL_TEST_TARGET}
    PRIVATE
    Qt6::Core
    Qt6::Test
)

set(WATCHDOG_TEST_TARGET test_watchdog)

qt_add_executable(${WATCHDOG_TEST_TARGET}
    tst_watchdog.cpp
    ${CMAKE_SOURCE_DIR}/src/watchdog.cpp
)

set_target_properties(${WATCHDOG_TEST_TARGET} PROPERTIES
    AUTOMOC ON
)

target_include_directories(${WATCHDOG_TEST_TARGET} PRIVATE ${CMAKE_SOURCE_DIR}/src)

target_link_libraries(${WATCHDOG_TEST_TARGET}
    PRIVATE
    Qt6::Core
    Qt6::Test
)

add_test(NAME ${LNURL_TEST_TARGET} COMMAND ${LNURL_TEST_TARGET})
add_test(NAME ${WATCHDOG_TEST_TARGET} COMMAND ${WATCHDOG_TEST_TARGET})
