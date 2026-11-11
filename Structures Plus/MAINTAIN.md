# Material-aware Maintain

Author: Vittorio

## Numeric quantity entry (0.35.1)

The shared Craft/Maintain slider is replaced by a native text-entry field.
Click the field, enter 1-999999 crafting batches and press Enter, then choose
Maintain. Batch semantics are unchanged: for a recipe producing two items per
batch, entering 25 displays a target of 50 items. The item totals remain visible
beside the input and on the buttons. Entering 50 now means a finite quantity;
only 0 selects continuous crafting. In that mode, Craft produces one batch.

Negative values, fractions, exponent notation, empty values and non-digit text
are rejected when committed. Escape restores the previous value. Changing the
crafting area resets the field and ends any old editing session. The native
text-entry control supplies mouse, keyboard and controller integration.

`scripts/structuresPlusMaintain/craftPanel.lua` atomically overlays the known
native crafting panel, and `scripts/structuresPlusMaintain/quantity.lua` supplies
the input adapter. Other sliders are unaffected. Tests cover input validation,
confirmation, cancellation, reset, both native panel sources, loader dispatch
and actual native order submission. Live UI appearance and input remain unverified.

## Material-aware stock counts

Crafting Maintain orders count the concrete outputs of the materials permitted
under **Requires**. Set one crafting area to Orange Logs and another to Pine
Logs: a displayed Maintain target of 50 Splitlogs now requires 50 Orange
Splitlogs and 50 Pine Splitlogs respectively.

This applies to all crafting recipes using native output definitions, including
mod-added variants, fixed outputs, tools, pottery, bricks, tiles, food and
container variants. If several inputs are permitted, their possible outputs
share the target. If different inputs produce the identical output object type,
they share that output's stock; the mod does not invent provenance variants.

Native batch sizes and target quantities are unchanged. Native stock search
distance, tribal availability, held items and queued-object handling remain in
effect. This is not a global inventory count. Production can exceed the target
by a batch or already active work, as in the base game.

Drying follows the actual evolution mapping for each output, so a dry pottery
target can count the corresponding dry result. Rotting never counts as drying.
The recipe's original resource/group definition determines which stages count.

Restart the game completely after updating. Existing saved Maintain orders use
the new calculation when loaded; no order recreation or save migration is
required. Current material restrictions are read on every availability update.

## Implementation and compatibility

`scripts/server/spMaintain.lua` resolves recipe output types and filters the
per-object-type counts returned by the native resource manager. Native plan
threshold transitions, resource callbacks and displayed nearby counts use the
same result. No recipe, global resource registry or saved-plan schema is changed.

The count call inside the native plan manager is replaced in memory through
`scripts/structuresPlusMaintain/install.lua`. The exact unique call must match;
unsupported source retains native behavior and logs a diagnostic. The loader
composes with the existing Structures Plus detour loader and Hammerstone.
Unknown third-party output schemas retain native counting. Mods that create
outputs outside native recipe metadata may require a dedicated adapter.

The overlay reads only the fixed game script path; it writes no game files,
executes no external commands and uses no network access. Drying traversal is
cycle-safe. Disabling Structures Plus leaves no custom Maintain save fields.

## Validation (2026-11-09)

`maintenance-tests/verify_material_maintain.py` passes independently against
`Sapiens_NICHT_BETA` (public release) and `Sapiens` (unstable beta), using their
Lua 5.1 runtime, native resource-count function and native threshold-update block.
Coverage includes separate 20/30 stocks, independent 50-item thresholds,
resumption below target, restriction changes, mixed inputs, held/remote/queued
items, tribes, fixed/default outputs, groups, byproducts, secondary input slots,
unknown schemas, drying cycles, loader order and unsupported source rejection.
All Structures Plus Lua files compile in both runtimes.

These are offline integration tests with simulated inventory and registries.
Live engine loading, UI interaction, multiplayer and actual crafting animations
have not been verified for this change.
