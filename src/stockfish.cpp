#include <cstdio>
#include <iostream>
#ifdef _WIN32
#include <fcntl.h>
#include <io.h>
#ifdef _WIN64
#define ssize_t __int64
#else
#define ssize_t long
#endif
#else
#include <unistd.h>
#endif

#include "fixes.h"
#include "stockfish.h"
#include <thread>

const char* QUITOK = "quitok\n";

void runMain();

void runMain() {}

int stockfishMain(int, char**);

int stockfish_init() {
    fakein.open();
    fakeout.open();
    return 0;
}

int _last_main_state = -2;

int stockfish_main() {
    _last_main_state = -1;
    int argc = 1;
    char* empty = (char*)malloc(0);
    *empty = 0;
    char* argv[] = {empty};
    int exitCode = stockfishMain(argc, argv);
    free(empty);

    fakeout << QUITOK << "\n";

#if _WIN32
    Sleep(100);
#else
    usleep(100000);
#endif

    fakeout.close();
    fakein.close();

    _last_main_state = exitCode;
    return exitCode;
}

void stockfish_start_main() {
    std::thread t(stockfish_main);
    t.detach();
}

int stockfish_last_main_state() { return _last_main_state; }

ssize_t stockfish_stdin_write(char* data) {
    std::string val(data);
    fakein << val << fakeendl;
    return val.length();
}

std::string data;

const char* stockfish_stdout_read(int trygetline) {
    if (trygetline) {
        if (fakeout.try_get_line(data)) {
            return data.c_str();
        }
    } else {
        if (getline(fakeout, data)) {
            return data.c_str();
        }
    }
    return nullptr;
}
