# Line Balance Platform

## V0.5.2 — Time Study test visibility fix

Time Study keeps independent cycle and element timers.

The widget test now checks the top-of-page session heading before scrolling
to the cycle-record section. This avoids expecting a widget that has been
scrolled out of the visible test viewport.

Element timing remains separate from cycle timing.

Rating, allowance, normal time and standard time remain intentionally deferred.
