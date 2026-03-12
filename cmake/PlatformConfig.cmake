if (WIN32)
    include(cmake/PlatformWindows.cmake)
elseif (APPLE)
    include(cmake/PlatformApple.cmake)
elseif (UNIX)
    include(cmake/PlatformUnix.cmake)
endif()

