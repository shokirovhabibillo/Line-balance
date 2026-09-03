# Line Balance Platform — V0.4.1

## Current milestone: Cycle Recording foundation

### Implemented
- Home dashboard
- Time Study navigation
- Cyclic / non-cyclic selection
- Session name field
- Live cycle stopwatch
- Start / Finish / Reset controls
- Cycle records with sequence number and timestamp
- Cycle summary: count, average, minimum, maximum and range
- Cycle deletion and sequence re-numbering
- Work element list
- Separate domain model and calculation service
- Unit and widget tests

### Deferred deliberately
- Persistent database
- Per-element timing/laps
- Productive/non-productive selection UI per element
- Rating
- Allowance
- Normal Time / Standard Time
- SOS/JES and STS/TIS
- Downtime
- Line Balance
- VSM
- HPV / Value Add
- Excel import/export
- PPTX reporting
- Authentication and full security layer

### Error-proofing in this milestone
- Finish is disabled until Start
- Start is disabled while a cycle is running
- Reset is only available during an active cycle
- Zero-duration cycle is not persisted
- Cycle numbering is rebuilt after deletion
- Calculation logic is isolated and unit-tested
- Widget tests explicitly verify that Time StudyPage opens before recording a cycle

## Next milestone
Per-element timing inside each cycle, with validation and a clear productive/non-productive classification workflow.
