# Architecture

## Time Study V0.5.3

Cycle time and element time are separate observations.

`CycleRecord.duration`
= elapsed time from Start cycle to Finish cycle.

`ElementRecord.duration`
= elapsed time from Start element to Finish element.

The element records are stored inside the corresponding cycle.

### Work element definition

Each `WorkElement` contains:

- name and productive/non-productive type;
- requirement classification: Safety, Quality, Sequence, Step-in-sequence,
  QCOS, or no requirement;
- verification method(s): visual, auditory, touch, measurement;
- basis/reference text for the requirement, standard or document, for example
  `CVIS 009-2025`, `Std-275537:2025`, or `QCOS 2344433:2025`.

Requirement and verification selections are stored with the element rather
than only displayed temporarily, so later reporting/export can use them.

### Element order

Work elements have an implicit order equal to their position in the session's
`_elements` list. The UI allows moving an element one position up or down.
Reordering is disabled while a cycle is running so the measurement sequence
cannot change in the middle of an observation.

Future layers:
Observed Time → Rating → Normal Time → Allowance → Standard Time.
