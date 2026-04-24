set(UNIT_TEST_COMMON_LIBS
    Qt6::Test
)

function(add_unit_test)
    set(options "")
    set(one_value_args NAME)
    set(multi_value_args SOURCES LIBRARIES)
    cmake_parse_arguments(UNIT_TEST "${options}" "${one_value_args}" "${multi_value_args}" ${ARGN})

    if(NOT UNIT_TEST_NAME)
        message(FATAL_ERROR "add_unit_test requires NAME")
    endif()
    if(NOT UNIT_TEST_SOURCES)
        message(FATAL_ERROR "add_unit_test requires SOURCES")
    endif()

    qt_add_executable(${UNIT_TEST_NAME}
        ${UNIT_TEST_SOURCES}
    )
    set_target_properties(${UNIT_TEST_NAME} PROPERTIES
        AUTOMOC ON
    )

    target_link_libraries(${UNIT_TEST_NAME}
        PRIVATE
        ${UNIT_TEST_COMMON_LIBS}
        ${UNIT_TEST_LIBRARIES}
    )

    add_test(NAME ${UNIT_TEST_NAME} COMMAND ${UNIT_TEST_NAME})
endfunction()

add_unit_test(
    NAME test_util
    SOURCES tst_util.cpp
    LIBRARIES blockstream_core
)

add_unit_test(
    NAME test_json
    SOURCES tst_json.cpp
    LIBRARIES blockstream_core
)

add_unit_test(
    NAME test_paymentparser
    SOURCES tst_paymentparser.cpp
    LIBRARIES blockstream_core
)

add_unit_test(
    NAME test_progress
    SOURCES tst_progress.cpp
    LIBRARIES blockstream_core
)

add_unit_test(
    NAME test_limitmodel
    SOURCES tst_limitmodel.cpp
    LIBRARIES blockstream_core
)

add_unit_test(
    NAME test_network
    SOURCES tst_network.cpp
    LIBRARIES blockstream_core
)

add_unit_test(
    NAME test_lightninglnurl
    SOURCES tst_lightninglnurl.cpp
    LIBRARIES blockstream_core
)

add_unit_test(
    NAME test_watchdog
    SOURCES tst_watchdog.cpp
    LIBRARIES blockstream_core
)
