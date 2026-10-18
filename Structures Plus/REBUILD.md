# Rebuild in Structures Plus

Author: Vittorio. Added in version 0.12.0.

Select a completed part or an unfinished construction and choose **Rebuild**. The original part is listed first, followed by compatible alternatives. Use the game's normal resource selectors to choose wood species, stone types or other supported material subtypes. Normal research, resource, tool and skill requirements still apply. Rebuilding uses the game's deconstruction and construction process; it is not an instant or free material swap.

## Compatible replacements

| Part | Rebuild choices |
| --- | --- |
| 45-degree floor wedge | Same size and shape in Split Log, Mud Brick or Tile |
| Right-triangle floor | Same leg length in Split Log, Mud Brick or Tile |
| Quarter-circle floor | Same radius in Split Log, Mud Brick or Tile |
| Short-edge triangle wall | Same edge length and height in the supported wall materials |
| Curved full wall, doorway or window wall | Same radius, full-height geometry; any supported wall material or opening form |
| Curved shortwall | Same radius and 1 m height in the supported wall materials |
| Hypotenuse full wall, doorway or small-window wall | Same triangle size and full height; any supported wall material or opening form |
| Hypotenuse shortwall | Same triangle size and 1 m height in the supported wall materials |
| Straight centered small-window wall | Native 4x2 wall, doorway and window group, including the mod's small-window alternatives |
| Wood Foundation 1x1 or 2x2 | Corresponding native foundation group plus the wooden foundation |
| Flat Foundation 4x4 | Dirt, Wood, Mud Brick, Brick or Stone Block Foundation 4x4 |
| Ramp Foundation 4x4 | Wood, Dirt, Mud Brick, Brick or Stone Block ramp with 1 m rise |
| Water Block | Rebuild the same Water Block size |

Rebuild does not resize a part or change a flat foundation into a ramp. Water Blocks remain separate from solid foundations. These boundaries preserve placement, connections and the intended footprint.

## Planted foundations and existing saves

Remove all plants, saplings and queued planting orders from a Dirt Foundation 4x4 before rebuilding it. Both the UI and server retain this protection. Native deconstruction handles the current construction inventory, including depleted soil; the selected replacement then follows its own normal recipe.

Existing part and model identifiers are unchanged. Completed parts and unfinished constructions resolve through their existing saved construction type, so they do not need to be replaced to acquire the Rebuild choices. Restart Sapiens after installing the update.
