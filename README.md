# Line Balance Platform — V0.6.0 Time Study V2

V0.6 is the Time Study V2 foundation built on the V0.5.4 FIXED8 baseline.

## Main changes
- Time Study setup is separated from the dedicated Time Check instrument screen.
- Work Element now supports Requirement, Xususiyati, Verification Method, Basis and Measurement Mode.
- Measurement modes:
  - Start + Finish Element
  - Cycle-linked / Finish-only
- Time Check shows measured, current and upcoming elements.
- Cycle and element timing remain independent.
- Cycle records can be deleted with confirmation.
- Statistics: observed, valid, excluded, average, median, mode, min, max, range and standard deviation.
- Selected time is a manual engineering choice and is not automatically replaced by the average.
- Excel export/import and Excel template are available from the Time Study menu.
- Basic Time Study history is retained for recent completed measurements.
- Existing V0.5.4 saved sessions remain readable through the legacy storage key.

## Excel structure
Exported workbooks contain:
- Session
- Work Elements
- Observations
- Summary

Import expects the Session and Work Elements sheets and can restore observations from the Observations sheet when present.

## Validation
The project CI remains pinned to Flutter 3.44.4. The container used to assemble this ZIP does not have Flutter/Dart installed, so local `flutter analyze`, `flutter test`, and APK build were not run here. CI must perform the authoritative validation.
