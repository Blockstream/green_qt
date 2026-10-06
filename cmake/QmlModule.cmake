qt_policy(SET QTP0004 NEW)

set_source_files_properties(qml/theme/Theme.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

# The module is backed by the blockstream_core static library, because qmltyperegistrar
# reads the metatypes of whichever target compiled the QML_ELEMENT headers. Qt generates
# a static plugin for it, which the executable links (see app/CMakeLists.txt).
qt_add_qml_module(blockstream_core
    URI Blockstream.Green
    VERSION 1.0
    DEPENDENCIES QtQuick
    QML_FILES ${BLOCKSTREAM_QML_FILES}
    RESOURCE_PREFIX /
    # A library-backed module has to say this; an executable-backed one got it for free.
    OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/Blockstream/Green"
    #ENABLE_TYPE_COMPILER
    NO_CACHEGEN
    NO_LINT
)
