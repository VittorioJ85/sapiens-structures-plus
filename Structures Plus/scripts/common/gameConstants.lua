local mod = {}

function mod:onload(gameConstants)
    -- Fixed target, not multiplication: repeated loading must not compound it.
    -- Shared by construction delivery and build actions (including native parts).
    -- This changes goal proximity, not collision tests or path search distance.
    gameConstants.buildPathProximityDistance = mj:mToP(5.0)
end

return mod
