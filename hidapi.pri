INCLUDEPATH += $${DEPS_PATH}/hidapi/include

unix:!macos:!android {
    LIBS += $${DEPS_PATH}/hidapi/lib/libhidapi-libusb.a
} else {
    LIBS += $${DEPS_PATH}/hidapi/lib/libhidapi.a
}

LIBS += $${DEPS_PATH}/libusb/lib/libusb-1.0.a
