/usr/bin/x86_64-w64-mingw32-g++ "$@" -Wl,-Bstatic,--whole-archive -lwinpthread -Wl,--no-whole-archive -lcrypt32 -lbcrypt -lws2_32 -liphlpapi -lssp -static-libgcc -static-libstdc++ -lwsock32
