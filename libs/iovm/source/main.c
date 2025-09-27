/*
    Io
*/

#include "IoState.h"
#include <stdio.h>

int main(int argc, char *argv[])
{
	IoState *self = IoState_new();
	IoState_argc_argv_(self, argc, (const char **)argv);
	IoState_runCLI(self);
	int exitResult = IoState_exitResult(self);
	IoState_free(self);
	return exitResult;
}
