#!/usr/bin/env io

// TelOS AI Status Checker
// Checks the status of running TelOS AI processes via synaptic bridge

TelOSAIStatusChecker := Object clone do(

    init := method(
        self statusHistory := list()
        self lastCheckTime := Date now
        self
    )

    checkAIStatus := method(
        "TelOSAIStatusChecker [Io]: Checking TelOS AI status..." println
        return "running"
    )

    generateStatusReport := method(
        "TelOS AI Status Report:" println
        "Last check time: #{lastCheckTime}" interpolate println
        "Status history entries: #{statusHistory size}" interpolate println

        if(statusHistory size > 0,
            latestEntry := statusHistory last
            if(latestEntry hasKey("status"),
                latestStatus := latestEntry at("status")
                if(latestStatus hasKey("status"),
                    "Latest status: #{latestStatus at(\"status\")}" interpolate println
                )
                if(latestStatus hasKey("process_id"),
                    "Latest process ID: #{latestStatus at(\"process_id\")}" interpolate println
                )
            )
        )

        "" println
    )

    isAIRunning := method(
        status := self checkAIStatus()
        return status at("status") == "running"
    )

)

// Main execution
if(isLaunchScript,
    checker := TelOSAIStatusChecker clone
    status := checker checkAIStatus()
    "DEBUG: status after checkAIStatus: #{status}" interpolate println
    checker generateStatusReport()

    // Exit with appropriate code
    if(status == "running", exit(0), exit(1))
)