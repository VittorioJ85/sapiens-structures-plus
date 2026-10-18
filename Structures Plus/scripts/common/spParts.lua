-- Stable registration order: changing keys or ordering can affect saved worlds.
-- Config and asset tables are generated data. Runtime behavior belongs in helpers.
return {
    {kind="triangle", configs="common/sl45Floors"},
    {kind="shortEdgeWall", configs="common/sl45Walls", assets="common/sl45WallModels"},
    {kind="curve", configs="common/sl90Parts", assets="common/sl90Models"},
    {kind="window", configs="common/slSquareWindows", assets="common/slSquareWindowModels"},
    {kind="hypotenuse", configs="common/slHypWalls", assets="common/slHypModels"},
    {kind="foundation", configs="common/slFoundations", assets="common/slFoundationModels"},
    {kind="pool", configs="common/slpoolParts"},
    {kind="column", configs="common/spColumns"},
}
