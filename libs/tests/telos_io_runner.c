#include "IoState.h"
#include "IoObject.h"

#include <stdio.h>
#include <stdlib.h>

#ifndef TELOS_IO_SCRIPT_PATH
#error "TELOS_IO_SCRIPT_PATH must be defined"
#endif

#ifndef TELOS_ADDON_SEARCH_PATH
#error "TELOS_ADDON_SEARCH_PATH must be defined"
#endif

static void report_failure(const char *message) {
    if (message) {
        fprintf(stderr, "[telos_io_runner] %s\n", message);
    }
}

int main(int argc, const char *argv[]) {
    (void)argc;
    (void)argv;

    if (setenv("TELOS_ADDON_PATH", TELOS_ADDON_SEARCH_PATH, 1) != 0) {
        perror("setenv(TELOS_ADDON_PATH)");
        return EXIT_FAILURE;
    }

    IoState *state = IoState_new();
    if (!state) {
        report_failure("Failed to allocate IoState");
        return EXIT_FAILURE;
    }

    IoState_argc_argv_(state, 0, NULL);

    IoObject *result = IoState_doFile_(state, TELOS_IO_SCRIPT_PATH);
    int exitCode = IoState_exitResult(state);

    if (!result) {
        report_failure("IoState_doFile_ returned NULL");
        exitCode = exitCode == 0 ? 1 : exitCode;
    }

    IoState_free(state);

    if (exitCode != 0) {
        report_failure("Io-driven bridge validation reported failure");
        return exitCode;
    }

    return EXIT_SUCCESS;
}
