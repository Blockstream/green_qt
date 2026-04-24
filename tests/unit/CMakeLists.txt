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
