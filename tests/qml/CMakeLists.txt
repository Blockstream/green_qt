find_package(Qt6 6.11 COMPONENTS QuickTest REQUIRED)

find_program(QML_TEST_RUNNER
    NAMES qmltestrunner
    HINTS
        "${QT_HOST_PATH}/${QT6_INSTALL_BINS}"
        "${QT6_INSTALL_PREFIX}/${QT6_INSTALL_BINS}"
        "${QT6_INSTALL_PREFIX}/bin"
    REQUIRED
)

set(QML_TEST_IMPORT_ARGS
    -import "${CMAKE_CURRENT_SOURCE_DIR}"
    -import "${CMAKE_SOURCE_DIR}/qml"
)

add_test(
    NAME test_js_util
    COMMAND "${QML_TEST_RUNNER}" -platform offscreen ${QML_TEST_IMPORT_ARGS} -input "${CMAKE_CURRENT_SOURCE_DIR}/tst_util.qml"
)

add_test(
    NAME test_js_analytics
    COMMAND "${QML_TEST_RUNNER}" -platform offscreen ${QML_TEST_IMPORT_ARGS} -input "${CMAKE_CURRENT_SOURCE_DIR}/tst_analytics.qml"
)
