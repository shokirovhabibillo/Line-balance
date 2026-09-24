# Line Balance Platform — V0.7.0

Industrial Engineering, Lean, VSM, Work Measurement and Continuous Improvement platform.

## V0.7 scope
- V0.6 Time Study preserved.
- Catalog: Product, Model, Process, Operation, Worker/Position, Line/Area.
- Line Balance: Takt Time, workload, bottleneck, balance %, theoretical stations, manual entry, Excel import/export, history.
- VSM: Current State / Future State, CT, C/O, Uptime, WIP, Lead Time, VA/NVA, Excel import/export, history.
- Downtime: category, cause, start/end, duration, productive/NVA, note, Excel import/export, history.
- Global History: Time Study, Catalog, Line Balance, VSM and Downtime events.
- Excel presentation standard: borders, bold headers, centered content, wrapped text, controlled column widths and readable row heights.

## Compatibility
- Flutter stable 3.44.4 in CI.
- Dart 3.12.x.
- SDK constraints: Dart >=3.12.0 <4.0.0; Flutter >=3.44.0.

## Important
Cygma CT / Cygma ET / HPV are not assigned formulas in this version. They remain reserved for the analysis layer until the user's company definitions are supplied.

No AGP/Gradle/Kotlin upgrade was introduced in V0.7.
