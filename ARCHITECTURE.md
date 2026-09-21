# Architecture — V0.6.0

## Time Study flow

Setup → Work Elements → Time Check → Observations → Statistics → Excel/History

## Domain separation

- `domain/` contains measurement models and enums.
- `application/` contains statistical calculations.
- `data/` contains persistence, Excel exchange and history.
- `presentation/` contains setup, Time Check and History screens.

## Timing model

Cycle duration is measured independently from element duration.

For `startFinish`, an element has its own Start/Finish interval.

For `cycleLinkedFinishOnly`, the cycle starts once and each element is cut from the continuous timeline by `Finish Element`. The next element begins immediately after the previous finish mark.

## Statistical model

Observed data is preserved. Excluded observations remain visible but are not included in valid statistics. Average, median, mode, minimum, maximum, range and standard deviation are calculated from valid observations.

`Selected time` is explicitly manual. The app does not silently decide that average/min/mode is the engineering standard time.

## Persistence

V0.6 uses the existing SharedPreferences foundation and a versioned V2 key. The V1 key is still readable so the previous baseline can migrate naturally.

## Excel

Excel exchange uses the `excel` package. File selection and save are handled through `file_picker`. The CI workflow remains unchanged and pins Flutter 3.44.4.
