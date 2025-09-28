// TELOS Telemetry Dashboard Prototype
// Provides convenience helpers for rendering conflict replay telemetry
// summaries and recent events using the Telos Bridge telemetry interface.

TelosTelemetryDashboard := Object clone do(
    defaultEventLimit := 5

    telemetry := method(
        if(Lobby hasSlot("Telos") not,
            Exception raise("Telos namespace unavailable; load TelosBridge first")
        )
        Telos Telemetry
        markChanged
    )

    bridge := method(
        if(Lobby hasSlot("Telos") not,
            Exception raise("Telos namespace unavailable; bridge access requires TelosBridge")
        )
        Telos Bridge
        markChanged
    )

    bridgeMetricsInterface := method(
        if(Lobby hasSlot("Telos") not,
            Exception raise("Telos namespace unavailable; bridge metrics access requires TelosBridge")
        )
        Telos BridgeMetrics
        markChanged
    )

    normalizeLimit := method(limit,
        if(limit isNil,
            defaultEventLimit,
            if(limit type == "Number",
                if(limit < 1,
                    1,
                    limit
                ),
                (limit asNumber) max(1)
            )
        )
        markChanged
    )

    fetch := method(limit,
        eventLimit := normalizeLimit(limit)
        telemetryMap := Map clone
        telemetryMap atPut("summary", telemetry summary)
        telemetryMap atPut("snapshot", telemetry snapshot(eventLimit))
        telemetryMap atPut("limit", eventLimit)
        telemetryMap
        markChanged
    )

    safeNumber := method(value, fallback,
        if(value isNil,
            fallback,
            if(value type == "Number",
                value,
                value asNumber
            )
        )
        markChanged
    )

    safeString := method(value, fallback,
        if(value isNil,
            if(fallback isNil, "n/a", fallback),
            value asString
        )
        markChanged
    )

    formatDuration := method(seconds,
        value := safeNumber(seconds, 0)
        rounded := ((value * 1000) floor) / 1000
        (rounded asString) .. "s"
        markChanged
    )

    formatMillis := method(milliseconds,
        value := safeNumber(milliseconds, 0)
        rounded := ((value * 1000) floor) / 1000
        (rounded asString) .. "ms"
        markChanged
    )

    formatPercent := method(rate,
        percent := safeNumber(rate, 0) * 100
        if(percent < 0, percent = 0)
        if(percent > 100, percent = 100)
        rounded := ((percent * 100) floor) / 100
        (rounded asString) .. "%"
        markChanged
    )

    formatTimestamp := method(timestamp,
        if(timestamp isNil,
            "n/a",
            seconds := safeNumber(timestamp, 0)
            date := Date clone
            date setSecondsSinceEpoch(seconds)
            date asString("%Y-%m-%d %H:%M:%S")
        )
        markChanged
    )

    buildSummaryLines := method(summaryMap,
        summary := summaryMap
        eventCount := safeNumber(summary at("event_count"), 0)
        iterations := safeNumber(summary at("total_iterations"), 0)
        errorCount := safeNumber(summary at("total_error_count"), 0)
        avgDuration := safeNumber(summary at("average_iteration_duration"), 0)
        p95Duration := safeNumber(summary at("p95_iteration_duration"), 0)
        errorsPerIteration := safeNumber(summary at("errors_per_iteration"), 0)
        wallclock := safeNumber(summary at("total_replay_wallclock"), 0)

        lines := List clone
        lines append("TELOS Conflict Replay Summary")
        lines append("--------------------------------")
        lines append("Events recorded: " .. eventCount asString)
        lines append("Total iterations: " .. iterations asString)
        lines append("Total errors: " .. errorCount asString)
        lines append("Average attempt duration: " .. formatDuration(avgDuration))
        lines append("P95 attempt duration: " .. formatDuration(p95Duration))
        lines append("Errors per iteration: " .. ((errorsPerIteration * 1000) floor / 1000) asString)
        lines append("Total replay wallclock: " .. formatDuration(wallclock))
        lines
        markChanged
    )

    buildEventLines := method(snapshotMap,
        events := snapshotMap at("events")
        lines := List clone
        lines append("")
        lines append("Recent conflict replay events")
        lines append("--------------------------------")

        if(events isNil or events size == 0,
            lines append("<no events recorded>")
            return lines
        )

        events foreach(event,
            workerId := event at("worker_id")
            workerLabel := if(workerId isNil, "n/a", workerId asString)
            timestamp := formatTimestamp(event at("timestamp"))
            captured := event at("captured_error")
            metrics := event at("metrics")
            iterations := if(metrics isNil, 0, safeNumber(metrics at("iterations"), 0))
            errorCount := if(metrics isNil, 0, safeNumber(metrics at("error_count"), 0))

            attemptCount := 0
            latestDuration := "n/a"
            if(metrics isNil not,
                errors := metrics at("errors")
                if(errors type == "List",
                    attemptCount = errors size
                    if(errors size > 0,
                        durationValue := errors last at("duration")
                        latestDuration = formatDuration(durationValue)
                    )
                )
            )

            summaryLine := "[" .. timestamp .. "] worker=" .. workerLabel ..
                " iterations=" .. iterations asString ..
                " errors=" .. errorCount asString ..
                " attempts=" .. attemptCount asString ..
                " last_duration=" .. latestDuration

            if(captured isNil not and captured asString size > 0,
                summaryLine = summaryLine .. " captured_error=\"" .. captured asString .. "\""
            )

            lines append(summaryLine)
        )

        lines
        markChanged
    )

    normalizeProxyIds := method(statusMap,
        ids := List clone
        proxyIds := statusMap at("proxy_ids")
        if(proxyIds type == "List",
            proxyIds foreach(pid,
                if(pid isNil not,
                    ids append(pid asString)
                )
            )
        ,
            if(proxyIds isNil not,
                ids append(proxyIds asString)
            )
        )
        ids
        markChanged
    )

    collectBridgeMetrics := method(options,
        ids := nil
        if(options type == "List",
            normalized := List clone
            options foreach(option,
                if(option isNil not,
                    normalized append(option asString)
                )
            )
            ids = normalized
        ,
            if(options isNil not,
                ids = List clone
                ids append(options asString)
            )
        )

        if(ids isNil,
            statusMap := bridge status
            ids = normalizeProxyIds(statusMap)
        )

        if(ids size == 0,
            Map clone
        ,
            metricsIface := bridgeMetricsInterface
            metricsSnapshot := metricsIface snapshot(ids)
            metricsPayload := metricsSnapshot at("metrics")

            if(metricsPayload type != "Map",
                Map clone
            ,
                if(metricsPayload at("invocations") isNil,
                    normalizedMap := Map clone
                    metricsPayload foreach(pid, entry,
                        normalizedMap atPut(pid asString, entry)
                    )
                    normalizedMap
                ,
                    result := Map clone
                    proxyId := ids at(0)
                    if(proxyId isNil,
                        result atPut("proxy", metricsPayload)
                    ,
                        result atPut(proxyId asString, metricsPayload)
                    )
                    result
                )
            )
        )
        markChanged
    )

    collectBridgeMetricsSummary := method(options,
        metricsIface := bridgeMetricsInterface
        summaryResponse := metricsIface summary(options)
        if(summaryResponse type != "Map",
            Map clone,
            summaryPayload := summaryResponse at("summary")
            if(summaryPayload type == "Map",
                summaryPayload,
                Map clone
            )
        )
        markChanged
    )

    buildBridgeMetricsLines := method(metricsMap, recentLimit,
        lines := List clone
        lines append("")
        lines append("Synaptic Bridge Dispatch Metrics")
        lines append("--------------------------------")

        if(metricsMap isNil or metricsMap size == 0,
            lines append("<no metrics recorded>")
            return lines
        )

        recentCount := 0
        if(recentLimit isNil not,
            recentCount = safeNumber(recentLimit, 0)
            if(recentCount < 0, recentCount = 0)
        )

        metricsMap foreach(pid, entry,
            if(entry type != "Map",
                lines append("Proxy " .. pid .. ": <no data>")
            ,
                invocations := safeNumber(entry at("invocations"), 0)
                failures := safeNumber(entry at("failures"), 0)
                avgDuration := formatMillis(entry at("averageDurationMs"))
                lastDuration := formatMillis(entry at("lastDurationMs"))
                successRate := formatPercent(entry at("successRate"))
                outcome := safeString(entry at("lastOutcome"), "n/a")
                message := safeString(entry at("lastMessage"), "n/a")
                errorText := entry at("lastError")

                line := "Proxy " .. pid .. ": invocations=" .. invocations asString ..
                    ", failures=" .. failures asString ..
                    ", success_rate=" .. successRate ..
                    ", avg=" .. avgDuration ..
                    ", last=" .. lastDuration ..
                    .. " (" .. outcome .. ")"

                if(message != "n/a",
                    line = line .. " msg=\"" .. message .. "\""
                )

                if(errorText isNil not,
                    line = line .. " error=\"" .. safeString(errorText, "") .. "\""
                )

                lines append(line)

                if(recentCount > 0,
                    recent := entry at("recent")
                    if(recent type == "List" and recent size > 0,
                        limit := recentCount min(recent size)
                        startIndex := recent size - limit
                        while(startIndex < recent size,
                            sample := recent at(startIndex)
                            sampleMessage := safeString(sample at("message"), "n/a")
                            sampleSuccess := sample at("success")
                            sampleDuration := formatMillis(sample at("durationMs"))
                            sampleTimestamp := formatTimestamp(sample at("timestamp"))
                            bullet := "  • " .. sampleTimestamp .. " :: " .. sampleMessage ..
                                " -> " .. (if(sampleSuccess == true, "success", "failure")) ..
                                " (" .. sampleDuration .. ")"
                            lines append(bullet)
                            startIndex = startIndex + 1
                        )
                    )
                )
            )
        )

        lines
        markChanged
    )

    buildBridgeSummaryLines := method(summaryMap,
        lines := List clone
        lines append("")
        lines append("Synaptic Bridge Dispatch Summary")
        lines append("--------------------------------")

        if(summaryMap isNil or summaryMap size == 0,
            lines append("<no summary available>")
            return lines
        )

        proxyCount := safeNumber(summaryMap at("proxyCount"), 0)
        totalInvocations := safeNumber(summaryMap at("totalInvocations"), 0)
        totalFailures := safeNumber(summaryMap at("totalFailures"), 0)
        successRate := formatPercent(summaryMap at("successRate"))
        failureRate := formatPercent(summaryMap at("failureRate"))
        averageDuration := formatMillis(summaryMap at("averageDurationMs"))
        lastTimestamp := summaryMap at("lastActivityTimestamp")
        lastProxy := summaryMap at("lastActivityProxy")

        lines append("Proxies monitored: " .. proxyCount asString)
        lines append("Total invocations: " .. totalInvocations asString)
        lines append("Total failures: " .. totalFailures asString .. " (" .. failureRate .. " | success " .. successRate .. ")")
        lines append("Average duration: " .. averageDuration)

        if(lastProxy isNil not,
            lines append("Last activity: proxy=" .. lastProxy asString .. " at " .. formatTimestamp(lastTimestamp))
        )

        topMessages := summaryMap at("topMessages")
        if(topMessages type == "List" and topMessages size > 0,
            lines append("Top recent messages:")
            topMessages foreach(item,
                if(item type == "Map",
                    message := safeString(item at("message"), "unknown")
                    count := safeNumber(item at("count"), 0)
                    lines append("  • " .. message .. " (" .. count asString .. " events)")
                )
            )
        )

        slowest := summaryMap at("slowestRecent")
        if(slowest type == "List" and slowest size > 0,
            lines append("Slowest recent dispatches:")
            slowest foreach(entry,
                if(entry type == "Map",
                    proxyId := safeString(entry at("proxyId"), "n/a")
                    message := safeString(entry at("message"), "unknown")
                    duration := formatMillis(entry at("durationMs"))
                    outcome := entry at("success")
                    outcomeLabel := if(outcome == true, "success", "failure")
                    timestamp := formatTimestamp(entry at("timestamp"))
                    lines append("  • proxy=" .. proxyId .. " msg=\"" .. message .. "\" " .. outcomeLabel .. " (" .. duration .. ") @ " .. timestamp)
                )
            )
        )

        lines
        markChanged
    )

    render := method(limit,
        telemetryData := fetch(limit)
        summaryLines := buildSummaryLines(telemetryData at("summary"))
        eventLines := buildEventLines(telemetryData at("snapshot"))
        combined := summaryLines clone
        combined appendSeq(eventLines)
        combined join("\n")
        markChanged
    )

    log := method(limit,
        output := render(limit)
        if(System hasSlot("log"),
            System log(output),
            output println
        )
        output
        markChanged
    )

    renderBridgeMetrics := method(recentLimit,
        summaryMap := collectBridgeMetricsSummary(nil)
        metricsMap := collectBridgeMetrics(nil)
        lines := buildBridgeSummaryLines(summaryMap)
        metricsLines := buildBridgeMetricsLines(metricsMap, recentLimit)
        lines appendSeq(metricsLines)
        lines join("\n")
        markChanged
    )

    logBridgeMetrics := method(recentLimit,
        output := renderBridgeMetrics(recentLimit)
        if(System hasSlot("log"),
            System log(output),
            output println
        )
        output
        markChanged
    )

    renderCombined := method(eventLimit, recentLimit,
        telemetryData := fetch(eventLimit)
        summaryLines := buildSummaryLines(telemetryData at("summary"))
        eventLines := buildEventLines(telemetryData at("snapshot"))
        bridgeSummary := buildBridgeSummaryLines(collectBridgeMetricsSummary(nil))
        metricsLines := buildBridgeMetricsLines(collectBridgeMetrics(nil), recentLimit)
        combined := summaryLines clone
        combined appendSeq(eventLines)
        combined appendSeq(bridgeSummary)
        combined appendSeq(metricsLines)
        combined join("\n")
        markChanged
    )

    logCombined := method(eventLimit, recentLimit,
        output := renderCombined(eventLimit, recentLimit)
        if(System hasSlot("log"),
            System log(output),
            output println
        )
        output
        markChanged
    )
)
