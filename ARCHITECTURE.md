# Architecture — V0.7

V0.7 extends V0.6 without replacing the Time Study implementation.

## Feature boundaries
- `features/time_study`: existing measurement workflow and Excel exchange.
- `features/catalog`: optional master data hierarchy.
- `features/line_balance`: standalone balancing plan and calculations.
- `features/vsm`: standalone current/future state value-stream data.
- `features/downtime`: standalone downtime log.
- `features/history`: global event history.
- `core/data/styled_excel.dart`: common Excel presentation layer.

## Integration rule
Modules remain usable independently. Time Study may later feed Line Balance; Downtime may later feed analysis; VSM does not require Time Study.

## Calculation rule
Only definitions that are explicit in the project scope are calculated. Cygma CT, Cygma ET and HPV are intentionally not given invented formulas.
