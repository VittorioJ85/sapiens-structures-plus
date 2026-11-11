return [==[function serverSapien:requestPathUpdateIfNotRequested(sapien)

   -- mj:log("serverSapien:requestPathUpdateIfNotRequested:", sapien.uniqueID)
   -- mj:log(debug.traceback())
    local sapienID = sapien.uniqueID

    if not requestedPathUpdatesBySapienID[sapienID] then


        --mj:log("requesting path")
        requestedPathUpdatesBySapienID[sapienID] = true
        local sharedState = sapien.sharedState
        local actionState = sharedState.actionState
        local incompletePathInfo = actionState.path
        --local nodes = pathInfo.nodes

        local orderState = sharedState.orderQueue[1]
        local orderStatePathCreationInfo = orderState.pathInfo

        if orderStatePathCreationInfo and orderStatePathCreationInfo.goalObjectIDOrNil and orderStatePathCreationInfo.initialObjectPos then
            local goalObject = serverGOM:getObjectWithID(orderStatePathCreationInfo.goalObjectIDOrNil)
            if goalObject and orderStatePathCreationInfo.initialObjectPos.x ~= goalObject.pos.x then

                local moveToPos = goalObject.pos
                
                if goalObject.objectTypeIndex == gameObject.types.sapien.index then --this code should be kept the same as in ai.lua addOrderForOrderInfo
                    if orderState.context and (orderState.context.planTypeIndex == plan.types.banish.index or orderState.context.planTypeIndex == plan.types.recruit.index) then --todo this is what, social plan? get in front of sapien's face
                        --disabled--mj:objectLog(sapien.uniqueID, "offsetting updated path in front of other sapien due to social plan")
                        local moveToDir = mat3GetRow(goalObject.rotation, 2)
                        local newMoveToPos = goalObject.pos + moveToDir * mj:mToP(6.0) --this number is very sensitive, < 4m is probably impossible for an elder to recruit an average sapien if they are walking
                        local clampToSeaLevel = true
                        moveToPos = worldHelper:getBelowSurfacePos(newMoveToPos, 1.0, physicsSets.walkable, nil, clampToSeaLevel)
                    end 
                end

                sharedState:set("orderQueue", 1, "pathInfo", "goalPosOrNil", moveToPos)
                sharedState:set("orderQueue", 1, "pathInfo", "initialObjectPos", goalObject.pos)
                --disabled--mj:objectLog(sapienID, "updating pathInfo in orderState:", moveToPos)
            end
        end



        local goalPosInfo = serverSapien:getGoalPosInfoForPathInfo(orderStatePathCreationInfo, sapien)
        
        --disabled--mj:objectLog(sapienID, "incompletePathInfo:", incompletePathInfo, " goalPosInfo:", goalPosInfo)

        if not incompletePathInfo.complete then
            if incompletePathInfo.nodes and incompletePathInfo.nodes[1] then
                local incompleteStartPos = incompletePathInfo.startPos or incompletePathInfo.nodes[1].pos
                if goalPosInfo.goalPos then
                    terrain:loadArea(normalize(goalPosInfo.goalPos))
                    local goalDistance2 = length2(goalPosInfo.goalPos - sapien.pos)
                    local prevGoalDistance2 = length2(goalPosInfo.goalPos - incompleteStartPos)
                    --disabled--mj:objectLog(sapienID, "goalDistance2:", goalDistance2, " prevGoalDistance2:", prevGoalDistance2)
                    if goalDistance2 > prevGoalDistance2 then
                        goalPosInfo.shouldCancel = true
                        --disabled--mj:objectLog(sapienID, "getting further away from goal, it is probably inaccessible goalDistance:", mj:pToM(math.sqrt(goalDistance2)), " prevGoalDistance:")
                        if orderState.objectID then
                            local object = serverGOM:getObjectWithID(orderState.objectID)
                            if object then
                                serverGOM:setInaccessible(object)
                            end
                        end
                    end
                end
            end
        end
        
        ----disabled--mj:objectLog(sapienID, "incompletePath goalPosInfo:", goalPosInfo)
        ----disabled--mj:objectLog(sapienID, "incompletePath goalPosInfo updated goalPos altitude difference:", mj:pToM(length(goalPosInfo.goalPos) - length(incompletePathInfo.goalPos)))

        if goalPosInfo.shouldCancel then
            local removeHeldObjectOrderContext = false
            serverSapien:cancelOrderAtQueueIndex(sapien, 1, removeHeldObjectOrderContext)
        else
            --disabled--mj:objectLog(sapienID, "requesting updated path")
            
            pathIDCounter = pathIDCounter + 1
            local pathID = pathIDCounter
            local unsavedState = serverGOM:getUnsavedPrivateState(sapien)
            unsavedState.waitingForPathID = pathID
            
            local orderObjectID = orderState.objectID
            local orderTypeIndex = orderState.orderTypeIndex
            local sequenceTypeIndex = actionState.sequenceTypeIndex

            pathCreator:getPath(sapienID, orderObjectID, sapien.pos, goalPosInfo.goalPos or incompletePathInfo.goalPos, orderStatePathCreationInfo.proximityType, orderStatePathCreationInfo.proximityDistance, orderStatePathCreationInfo.options, function(createdPathInfo)
                pathUpdateReceived(sapienID, orderObjectID, orderTypeIndex, sequenceTypeIndex, pathID, createdPathInfo)
            end)
        end
    end
end


]==]
