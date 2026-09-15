# Line Balance Platform

## V0.5.4 — Time Study local persistence — Work element requirements and ordering

Time Study keeps independent cycle and element timers.

### Local persistence

The current Time Study session is automatically saved on the device. The following survive leaving the Time Study page and opening it again:
- session name;
- cyclic/non-cyclic selection;
- work elements and their order;
- element requirements, verification methods and basis;
- completed cycle records and element measurements.

An active unfinished stopwatch is intentionally not resumed after the page is closed, because its elapsed time cannot be reconstructed reliably after the UI lifecycle ends.

### Work elements

The Ish elementlari section now supports:

1. Changing the order number of an added work element with Up/Down controls.
2. Selecting required compliance categories:
   - Xavfsizlik
   - Sifat
   - Ketma-ketlik
   - Qadam ichidagi ketma-ketlik
   - QCOS
   - Hech narsa
3. Selecting verification method(s):
   - Ko‘rish
   - Eshitish
   - Teginish
   - O‘lchash
4. Entering the basis/reference for the requirement or verification, for
   example `CVIS 009-2025`, `Std-275537:2025`, or `QCOS 2344433:2025`.
5. Editing all of the above after the element is created.

Reordering, editing and deleting are disabled while a cycle is running to
protect the integrity of an active time study.

Rating, allowance, normal time and standard time remain intentionally
 deferred.
