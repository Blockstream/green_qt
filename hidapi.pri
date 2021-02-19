INCLUDEPATH += $${DEPS_PATH}/hidapi/include

LIBS += $${DEPS_PATH}/libusb/lib/libusb-1.0.a

unix:!macos:!android {
    LIBS += $${DEPS_PATH}/hidapi/lib/libhidapi-libusb.a
} else {
    LIBS += $${DEPS_PATH}/hidapi/lib/libhidapi.a
}
