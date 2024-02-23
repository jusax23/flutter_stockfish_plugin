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

const char* QUITOK = "quitok\n";

void runMain() {}

int main(int, char**);

int stockfish_init() {
    fakein.open();
    fakeout.open();
    return 0;
}

int stockfish_main() {
    int argc = 1;
    char* empty = (char*)malloc(0);
    *empty = 0;
    char* argv[] = {empty};
    int exitCode = main(argc, argv);
    free(empty);

    fakeout << QUITOK << "\n";

#if _WIN32
    Sleep(100);
#else
    usleep(100000);
#endif

    fakeout.close();
    fakein.close();

    return exitCode;
}

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