# Architecture v0.3

## Current milestone: Time Study foundation

Implemented:
- Home dashboard
- Time Study navigation
- Cyclic / non-cyclic session selection
- Session name
- Basic live stopwatch
- Add/remove work elements
- Productive/non-productive domain classification
- Widget tests for navigation and Time Study opening

Intentionally deferred:
- persistent database
- cycle records
- automatic lap/cycle capture
- rating
- allowance
- Standard Time calculation
- SOS/JES and STS/TIS workflows
- Excel import/export

## Design rule

The stopwatch is a UI prototype only at this stage. Production measurement data must
be persisted through a domain/application layer before the feature is considered complete.

Next milestone:
Time Study cycle recording + validation + persistent domain model.
