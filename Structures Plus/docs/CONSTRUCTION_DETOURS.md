# Structures Plus: construction detours

Author: Vittorio. Integrated in Structures Plus 0.19.1.

Allows construction-material delivery to continue along valid incomplete paths
even when an intermediate segment increases straight-line distance to the goal.
Native search, collision, proximity and explicit inaccessible results remain
unchanged. Other order types retain the original distance-increase rule.

The guard cancels after two consecutive continuations with less than 0.5 m
displacement, a third segment endpoint within 2 m of earlier recorded endpoints,
more than 32 segment continuations, or more than 512 m accumulated endpoint
displacement. These are conservative experimental bounds, not engine limits
or a guarantee of complete route discovery. Endpoint displacement is not the
full distance walked. State resets for a different order ID, object or moved
goal and is held in memory only.

The mod applies an exact-function-source overlay through fileUtils while the
server script is loaded. It replaces only the distance cancellation condition;
it does not write the game script or executable. The entire reviewed function
must match, otherwise the original is retained with an unsupported-source log.
Other mods' function wrappers can still run normally. Public and Unstable
installed continuation functions matched when this release was prepared.

Look for `[StructuresPlusDetours] exact-source patch active 0.19.1` at startup,
and `allow detour` or a bounded cancellation reason during a relevant attempt.
Pathfinding Diagnostics is optional and is not bundled or required.
The standalone correction was verified in the Unstable world with Siko reaching
the construction site and beginning work. The integrated lifecycle is covered by
offline tests on both editions; a fresh in-game integration check is still needed.
No save migration or network access is performed. The loader accepts only the
reviewed local engine module; it does not read remote or save-provided code.
