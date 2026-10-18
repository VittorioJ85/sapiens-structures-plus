-- Dimensions are in metres. Persistent keys must not change after release.
return {
 {key="spc_wood",label="Wood Column 2m",family="wood",height=2,count=2,source="mudBrickColumn",recipeSource="splitLogFloor1x1"},
 -- Keep the former capital IDs so existing objects upgrade in place.
 {key="spc_cap_wood",label="Wood Column 1m",family="wood",height=1,count=1,source="mudBrickColumn",recipeSource="splitLogFloor1x1"},
 {key="spc_cap_mud",label="Mud Brick Column 1m",family="mud",height=1,count=1,source="mudBrickColumn"},
 {key="spc_cap_stone",label="Stone Block Column 1m",family="stone",height=1,count=1,source="stoneBlockColumn"},
 {key="spc_cap_brick",label="Fired Brick Column 1m",family="brick",height=1,count=1,source="mudBrickColumn",recipeSource="brickWall"},
 {key="spc_brick",label="Fired Brick Column 2m",family="brick",height=2,count=2,source="mudBrickColumn",recipeSource="brickWall"},
}
