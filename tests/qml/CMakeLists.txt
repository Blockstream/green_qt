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

add_test(
    NAME test_qml_amountvalidator
    COMMAND "${QML_TEST_RUNNER}" -platform offscreen ${QML_TEST_IMPORT_ARGS} -input "${CMAKE_CURRENT_SOURCE_DIR}/tst_amountvalidator.qml"
)
add_test(
    NAME test_qml_filterpopup
    COMMAND "${QML_TEST_RUNNER}" -platform offscreen ${QML_TEST_IMPORT_ARGS} -input "${CMAKE_CURRENT_SOURCE_DIR}/tst_filterpopup.qml"
)
add_test(
    NAME test_qml_addressfilterpopup
    COMMAND "${QML_TEST_RUNNER}" -platform offscreen ${QML_TEST_IMPORT_ARGS} -input "${CMAKE_CURRENT_SOURCE_DIR}/tst_addressfilterpopup.qml"
)
add_test(
    NAME test_qml_accountfilterpopup
    COMMAND "${QML_TEST_RUNNER}" -platform offscreen ${QML_TEST_IMPORT_ARGS} -input "${CMAKE_CURRENT_SOURCE_DIR}/tst_accountfilterpopup.qml"
)
add_test(
    NAME test_qml_assetfilterpopup
    COMMAND "${QML_TEST_RUNNER}" -platform offscreen ${QML_TEST_IMPORT_ARGS} -input "${CMAKE_CURRENT_SOURCE_DIR}/tst_assetfilterpopup.qml"
)
add_test(
    NAME test_qml_addresstypelabel
    COMMAND "${QML_TEST_RUNNER}" -platform offscreen ${QML_TEST_IMPORT_ARGS} -input "${CMAKE_CURRENT_SOURCE_DIR}/tst_addresstypelabel.qml"
)
add_test(
    NAME test_qml_transactionstatusbadge
    COMMAND "${QML_TEST_RUNNER}" -platform offscreen ${QML_TEST_IMPORT_ARGS} -input "${CMAKE_CURRENT_SOURCE_DIR}/tst_transactionstatusbadge.qml"
)
add_test(
    NAME test_qml_transactionprogress
    COMMAND "${QML_TEST_RUNNER}" -platform offscreen ${QML_TEST_IMPORT_ARGS} -input "${CMAKE_CURRENT_SOURCE_DIR}/tst_transactionprogress.qml"
)
add_test(
    NAME test_qml_transactionamounts
    COMMAND "${QML_TEST_RUNNER}" -platform offscreen ${QML_TEST_IMPORT_ARGS} -input "${CMAKE_CURRENT_SOURCE_DIR}/tst_transactionamounts.qml"
)
add_test(
    NAME test_qml_linechart
    COMMAND "${QML_TEST_RUNNER}" -platform offscreen ${QML_TEST_IMPORT_ARGS} -input "${CMAKE_CURRENT_SOURCE_DIR}/tst_linechart.qml"
)

# Run with the app's Controls style instead of the platform default, so results
# don't depend on the host (e.g. the macOS style's BusyIndicator images).
get_property(QML_TESTS DIRECTORY PROPERTY TESTS)
set_tests_properties(${QML_TESTS} PROPERTIES
    ENVIRONMENT "QT_QUICK_CONTROLS_STYLE=Material;QT_QUICK_CONTROLS_CONF=${CMAKE_SOURCE_DIR}/qml/qtquickcontrols2.conf"
)
