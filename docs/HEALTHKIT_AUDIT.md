# HealthKit integration audit — VITAL 3.0

## Baseline findings
The inherited HealthStore launches many independent HealthKit queries in `refresh()`. The current `isRefreshing` flag is cleared by the steps query alone, while other queries can still be running. The UI can therefore report refresh completion before all metrics, trends and blood-pressure correlations have returned.

Query helpers generally return optional values and do not consistently propagate HealthKit errors. A nil value can represent multiple states: no samples, query failure, or unsupported type. HealthKit intentionally does not expose a reliable read-authorization denial state.

## Required diagnostic outcomes
- loaded: query returned one or more samples / an aggregate value
- empty: query completed successfully with no samples
- unsupported: the HealthKit type is unavailable on this OS/device
- failed: HealthKit returned a query error

Do not label empty results as denied permission. Explain that the user can inspect access in Apple Health settings, but VITAL cannot determine the reason for an empty read.

## Refresh acceptance criteria
- One refresh lifecycle and one completion point.
- isRefreshing remains true until all requested queries finish.
- A failed query does not prevent unrelated metrics from loading.
- Each metric is reset or updated deterministically so stale values are not presented as current.
- lastUpdated is set only after the full refresh completes.
- Repeated refreshes cannot let an older response overwrite newer data.

## Metric integrity
- Preserve HealthKit units and convert explicitly at the boundary.
- Blood pressure systolic and diastolic values remain paired from the same correlation and timestamp.
- Display sample dates/freshness where relevant.
- Missing values remain missing; never substitute zero.
- Do not infer permission state from an empty query result.

## Recovery and reports
- Overnight recovery remains a distinct morning-oriented estimate.
- Body Battery remains a dynamic daytime estimate, not a direct HealthKit measurement.
- Morning report snapshots are captured only after a complete refresh and remain immutable for that day.
- Missing evidence remains visible; do not fabricate precision.

## Verification gates
1. Source review and static checks.
2. Xcode compile on macOS runner.
3. Inspect build logs and app metadata.
4. Confirm expected IPA artifact exists.
5. Only then offer the build for sideload testing.
