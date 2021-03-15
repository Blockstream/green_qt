g++ %* -Wl,-Bstatic,--whole-archive -lwinpthread -Wl,--no-whole-archive -lcrypt32 -lbcrypt -lws2_32 -liphlpapi -lssp -static-libgcc -static-libstdc++ -lwsock32 -lhid -lSetupAPI 
