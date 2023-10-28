#include <cstdio>
#include <iostream>
#ifdef _WIN32
#include <fcntl.h>
#include <io.h>
#define STDIN_FILENO 0
#define STDOUT_FILENO 1
#define STDERR_FILENO 2
#ifdef _WIN64
#define ssize_t __int64
#else
#define ssize_t long
#endif
#else
#include <unistd.h>
#endif

#define BUFFER_SIZE 1024

#include "stockfish.h"

const char *QUITOK = "quitok\n";

int main(int, char **);

int stockfish_init() {
    std::cout << "Init Stockfish: Nothing todo!";
    return 0;
}

int stockfish_main() {
    int argc = 1;
    char *argv[] = {(char *)""};
    int exitCode = main(argc, argv);

    fakeout << QUITOK << "\n";

    usleep(100000);

    fakeout.close();
    fakein.close();

    return exitCode;
}

ssize_t stockfish_stdin_write(char *data) {
    std::string val(data);
    fakein << val << fakeendl;
    return val.length();
}

std::string data;
char buffer[BUFFER_SIZE + 1];

char *stockfish_stdout_read() {
    if (getline(fakeout, data)) {
        size_t len = data.length();
        size_t i;
        for (i = 0; i < len && i < BUFFER_SIZE; i++) {
            buffer[i] = data[i];
        }
        buffer[i] = 0;
        return buffer;
    }
    return NULL;
}