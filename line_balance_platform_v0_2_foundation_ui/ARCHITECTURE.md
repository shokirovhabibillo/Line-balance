# Architecture v0.2

## Logical layers

presentation -> application/use cases -> domain -> data/infrastructure

## Feature boundaries

features/
- time_study/
- downtime/
- line_balance/
- vsm/
- value_analysis/
- four_m/
- hr/
- improvement/
- training/
- reports/
- security/

## Current milestone

Implemented:
- Material 3 app shell
- Home dashboard
- Six module entry cards
- Widget smoke test
- CI analyze/test/release APK pipeline
- Android generation when android/ is absent

Deferred intentionally:
- database
- Excel/PPTX dependencies
- authentication
- production data
- calculations
- VSM editor

Next feature milestone: Time Study domain modelling.
