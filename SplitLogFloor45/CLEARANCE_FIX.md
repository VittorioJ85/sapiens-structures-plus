# Covered terrain clearance — 0.13.1

Author: Vittorio

Building a floor beside a completed solid foundation can request terrain clearing
at a vertex under that foundation. The affected terrain vertices are selected by
the native engine and can lie outside the floor's footprint. Workers can repeatedly
follow incomplete paths to the buried point instead of bringing building materials.

Structures Plus now excludes deeply covered terrain vertices from the native
building-clearance requirement. This applies only to completed, unscaled, solid
4x4 Dirt, Mud Brick, Brick, and Stone Block Foundations. It excludes wooden shells,
ramps, unfinished foundations, exposed edges, and vegetation on the deck.

The interior check uses the foundation's local rotated frame: |x| and |z| < 1.95 m,
and -2.05 <= y <= -0.25 m. The 5 cm base tolerance accommodates small placement
offsets; the reproduced foundation sat 1.05 cm above the target terrain point.
Blocks with a larger gap underneath are not treated as covering that point.

Already-running construction clearance orders targeting such a point are cancelled
through the native order-cleanup API when they request a path continuation. The
construction plan is retained so the AI can select its next subtask. Explicit
terrain-clearing orders and hauling orders are unaffected. The code does not clear
vegetation, award resources, alter terrain, modify path nodes, or enlarge reach.

Restart the game to load this version. Resume the world and allow the worker's
current path segment to reach its next continuation request. Verify that the worker
leaves the clearance loop and the tile's build sequence advances. Other legitimate
resource or access requirements can still block the build.

Validation: 54 LuaJIT checks using mocked engine services, including the saved
rotated-foundation/terrain-point fixture. Actual engine navigation and completion
of the construction have not yet been verified in game.
