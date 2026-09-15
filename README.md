# Line Balance Platform

## V0.5.1 — Independent Cycle and Element Timing

Time Study now keeps the cycle stopwatch independent from the element stopwatch.

Flow:
Start cycle → Start element → Finish element → next element → Finish cycle.

The cycle duration is always the actual elapsed cycle time.
Element durations are stored separately as observed element times.

Rating, allowance, normal time and standard time remain intentionally deferred.
