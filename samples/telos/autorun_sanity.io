// Minimal autorun sanity check: verify IoTelos.io loaded and logging works
writeln("[SANITY] Telos autorun sanity starting")
Telos logs append("logs/autorun_sanity.log", "[sanity] begin " .. Date clone now asString)
// touch a babs run.log line as well
Telos logs append("logs/babs/run.log", "[sanity] hello from autorun")
Telos logs append("logs/autorun_sanity.log", "[sanity] end " .. Date clone now asString)
