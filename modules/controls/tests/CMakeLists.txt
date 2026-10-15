find_package(Qt6 6.11 COMPONENTS Gui QuickTest REQUIRED)

qt_add_executable(test_qml_controls main.cpp)
set_target_properties(test_qml_controls PROPERTIES AUTOMOC ON)
target_compile_definitions(test_qml_controls PRIVATE QUICK_TEST_SOURCE_DIR="${CMAKE_CURRENT_SOURCE_DIR}")
target_link_libraries(test_qml_controls PRIVATE Qt6::Gui Qt6::QuickTest blockstream_controlsplugin blockstream_testingplugin)

foreach(TEST_NAME uibutton uiiconbutton uitextfield uiradio uicheckbox uitoggle uilink uitabs)
    add_test(
        NAME test_qml_${TEST_NAME}
        COMMAND test_qml_controls -platform offscreen -input "${CMAKE_CURRENT_SOURCE_DIR}/tst_${TEST_NAME}.qml"
    )
    set_tests_properties(test_qml_${TEST_NAME} PROPERTIES
        ENVIRONMENT "QT_QUICK_CONTROLS_STYLE=Material;QT_QUICK_CONTROLS_CONF=${CMAKE_SOURCE_DIR}/qml/qtquickcontrols2.conf"
    )
endforeach()
