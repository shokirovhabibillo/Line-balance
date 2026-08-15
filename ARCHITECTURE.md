# Architecture v0.4

Implemented:
- Structured CycleRecord domain model
- Separate TimeStudyCalculator
- Start / Finish / Reset cycle controls
- Cycle list with sequence numbers
- Cycle summary: count, average, min, max, range
- Cycle deletion and re-numbering
- Unit tests for calculations
- Widget test for recording a cycle

Deferred:
- persistent database
- per-element lap timing
- rating
- allowance
- Normal Time / Standard Time
- SOS/JES and STS/TIS
- Excel/PPTX
- authentication/security

Error-proofing:
- Finish disabled until Start
- Start disabled while running
- Reset only while running
- zero-duration cycle is not saved
- calculation logic is isolated and tested

Next: per-element timing and validation.
