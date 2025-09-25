setlocal enabledelayedexpansion

call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" x64

set PREFIX=C:\deps
set CMAKE_PREFIX_PATH=C:\deps;C:\depends\windows-x86_64

lib /def:C:\depends\windows-x86_64\bin\libgreen_gdk.def /out:C:\depends\windows-x86_64\lib\libgreen_gdk.lib /machine:x64
lib /def:C:\depends\windows-x86_64\bin\libserialport-0.def /out:C:\depends\windows-x86_64\lib\libserialport-0.lib /machine:x64

call C:\qt\6.8.3\msvc2022_64\bin\qt-cmake -S C:\src -B C:\src\bld

cmake --build C:\src\bld --config Release

C:\qt\6.8.3\msvc2022_64\bin\windeployqt.exe --qmldir C:\src\qml C:\src\bld\Release\blockstream.exe

copy C:\depends\windows-x86_64\bin\libgreen_gdk.dll C:\src\bld\Release\
copy C:\depends\windows-x86_64\bin\libserialport-0.dll C:\src\bld\Release\

endlocal
