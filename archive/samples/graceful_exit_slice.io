// Graceful Exit Vertical Slice
// Touches UI (heartbeat), FFI (pyEval), and Persistence (WAL + snapshots), then exits 0

writeln("-- graceful_exit_slice: start (no-morph variant)")

// Breathe and persist by invoking the new command (exits 0)
// Instrumentation: WAL marks around the invocation for DOE tracing
pre := Map clone; pre atPut("t", Date clone now asNumber)
Telos mark("run.exit.invoke.pre", pre)
Telos commands run("run.exit", list("graceful"))
// Defensive fallback: in case commands.run returned without exiting
do(
	rei := Map clone; rei atPut("reason", "direct-fallback")
	Telos runAndExit(rei)
)
// This line may not execute if System exit(0) succeeds inside runAndExit
post := Map clone; post atPut("t", Date clone now asNumber)
Telos mark("run.exit.invoke.post", post)
