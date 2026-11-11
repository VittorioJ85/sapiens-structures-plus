-- Retain persisted identifiers/order for saved objects and unfinished orders.
-- Retired entries are compatibility definitions, not available building parts.
return {
    {key="spDoorWood", source="splitLogWallDoor", retired=true,
     label="Split Log Wall with Automatic Door", leafKey="splitLog_12"},
    {key="spDoorWoodInsert", source="splitLogWallDoor", standalone=true, originHeight=1,
     label="Automatic Wood Door", leafKey="splitLog_1"},
    {key="spDoorCurve4", source="splitLogWallDoor", standalone=true, originHeight=1,
     label="Automatic Wood Door for Curved Walls 4 m", leafKey="splitLog_1", radius=4, leafModel="spDoorLeafCurve4", snapKey="spDoorCurve4"},
    {key="spDoorCurve2", source="splitLogWallDoor", standalone=true, originHeight=1,
     label="Automatic Wood Door for Curved Walls 2 m", leafKey="splitLog_1", radius=2, leafModel="spDoorLeafCurve2", snapKey="spDoorCurve2"},
}
