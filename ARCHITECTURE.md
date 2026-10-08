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

## V0.7.1 — 4M Foundation
4M is introduced as an optional platform foundation. Workstation context combines Man, Machine, Material and Method without forcing Time Study, Line Balance, VSM or Downtime dependencies. Future integrations should consume the same IDs/context rather than duplicating data.

People: employee, position, brigade, station, shift, JIT level, flexibility by operation, attendance status.
Machine: equipment, station, status, cycle time.
Material: part number, required quantity, available quantity, shortage.
Method: operation, standard, requirement, verification, with a placeholder for structured Error Proofing/Agar logic.
