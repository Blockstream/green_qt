!defined(QZXING_PATH, var): error(Run qmake with QZXING_PATH set. See BUILD.md for more details.)

CONFIG += qzxing_qml qzxing_multimedia enable_decoder_qr_code enable_encoder_qr_code

include($${QZXING_PATH}/src/QZXing-components.pri)
