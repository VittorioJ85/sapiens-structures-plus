# Water Blocks in Structures Plus

Author: Vittorio. Integrated in Structures Plus 0.11.0 from Pool Prototype 0.3.0.

## Placement and access

Water Block 2x2 and Water Block 4x4 appear under their own Water Blocks build-menu entry, using the 2x2 block preview, after the original digging research. Both are 2 m deep and allow vertical placement adjustment. They require two and eight Dirt respectively.

The mean water surface is 3 cm above the placement origin. Provide an accessible entrance below the waterline and a basin floor at least approximately 1.2 m below the surface. An underwater navigation surface lies 0.98 m below the placement origin, with nine walk nodes for 2x2 pools and 25 for 4x4 pools. Entrance and exit paths must reach this level; Sapiens do not automatically jump over a pool wall.

The 4x4 pool uses four matching 2 m wave tiles. Since 0.16.5 these reuse the same physical meshes through native resource placements, saving 64 GLBs. They share one animation phase. Place neighboring pieces on the same 2 m grid and at the same height for matching wave boundaries. Ninety-degree rotations are supported. Pools do not clear terrain automatically; remove protruding terrain before placement.

## Water and movement

From version 0.11.3, Water Blocks use the native water color from the original prototype. The legacy `slpool_waterBlue` material key remains for mesh compatibility; it no longer implies a custom blue tint.

Both sizes share 64 synchronized wave frames over five game seconds, with approximately two centimetres of displacement around the mean height. Pause and game speed affect the common wave clock. Completed pools provide local water heights independently of sea level. Server movement uses the mean swimming height; client visuals follow the animated surface.

The mod reuses native swimming animations and Deep Water movement costs. Seated Sapiens, unfinished pools, rim walkers and areas obstructed by shallow terrain or raised floors are excluded. On pool exit, both native movement-cache entries are cleared together to prevent the previously reported crash.

Pools do not block rain and use `preventGrassAndSnow = false`, like every other Structures Plus part.

## Limits

This is a local kinematic swimming system with precomputed waves. It does not simulate fluid flow, overflow, water collection, boat buoyancy or wind-driven changes in wave amplitude. The material is opaque; ocean refraction and underwater transparency are not reproduced. The underwater navigation surface may support other physical objects.

## Save compatibility

The saved keys `slpool_water2x2` and `slpool_water4x4`, their `build_` counterparts, all model names and the `slpool_waterBlue` material remain unchanged. Existing pools do not need rebuilding. The merge changes which mod supplies these definitions; the standalone Pool Prototype must be disabled or archived. Keep Structures Plus enabled in worlds containing these parts.
