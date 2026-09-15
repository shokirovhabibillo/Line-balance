# Architecture

## Time Study V0.5.1

Cycle time and element time are separate observations.

`CycleRecord.duration`
= elapsed time from Start cycle to Finish cycle.

`ElementRecord.duration`
= elapsed time from Start element to Finish element.

The element records are stored inside the corresponding cycle.

This prevents element timing from changing or resetting the cycle stopwatch.

Future layers:
Observed Time → Rating → Normal Time → Allowance → Standard Time.
