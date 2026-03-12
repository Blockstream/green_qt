if (QT_FEATURE_static)
    find_library(AVCODEC NAMES libavcodec.a REQUIRED)
    find_library(AVDEVICE NAMES libavdevice.a REQUIRED)
    find_library(AVFILTER NAMES libavfilter.a REQUIRED)
    find_library(AVFORMAT NAMES libavformat.a REQUIRED)
    find_library(AVUTIL NAMES libavutil.a REQUIRED)
    find_library(SWSCALE NAMES libswscale.a REQUIRED)
    find_library(SWRESAMPLE NAMES libswresample.a REQUIRED)
    find_library(POSTPROC NAMES libpostproc.a REQUIRED)
    set(FFMPEG_LIBRARIES
        /depends/linux-x86_64/plugins/multimedia/libffmpegmediaplugin.a
        ${AVDEVICE}
        ${AVFILTER}
        ${AVFORMAT}
        ${AVCODEC}
        ${POSTPROC}
        ${SWRESAMPLE}
        ${SWSCALE}
        ${AVUTIL}
        Xrandr
        Xrender
    )
    message(STATUS "FFMPEG_LIBRARIES: ${FFMPEG_LIBRARIES}")
endif()

find_package(Qt6 6.11 CONFIG REQUIRED NO_MODULE COMPONENTS WaylandClient)

