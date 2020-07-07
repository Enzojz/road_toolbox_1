-- local dump = require "luadump"
local coor = require "rtb/coor"
local func = require "rtb/func"
local pipe = require "rtb/pipe"

-- local dbg = require("LuaPanda")
local state = {
    use = false,
    window = false,
    distance = 1,
    fn = {}
}

local setSpacingText = function(spacing)
    return string.format("%0.1f%s", spacing, _("METER"))
end

local createWindow = function()
    if not api.gui.util.getById("roadtoolbox.use") then
        local menu = api.gui.util.getById("menu.construction.road.settings")
        local menuLayout = menu:getLayout()
        
        local useComp = api.gui.comp.Component.new("ParamsListComp::ButtonParam")
        local useLayout = api.gui.layout.BoxLayout.new("VERTICAL")
        useComp:setLayout(useLayout)
        useComp:setId("roadtoolbox.use")
        
        local use = api.gui.comp.TextView.new(_("ROAD_TOOLBOX"))
        
        local useButtonComp = api.gui.comp.ToggleButtonGroup.new(0, 0, false)
        local useNoText = api.gui.comp.TextView.new(_("NO"))
        local useSharpXText = api.gui.comp.TextView.new(_("SHARP_XING"))
        local usePRoadsText = api.gui.comp.TextView.new(_("P_ROADS"))
        local useNo = api.gui.comp.ToggleButton.new(useNoText)
        local useSharpX = api.gui.comp.ToggleButton.new(useSharpXText)
        local usePRoads = api.gui.comp.ToggleButton.new(usePRoadsText)
        useNoText:setName("ToggleButton::Text")
        useSharpXText:setName("ToggleButton::Text")
        usePRoadsText:setName("ToggleButton::Text")
        useButtonComp:setName("ToggleButtonGroup")
        useButtonComp:add(useNo)
        useButtonComp:add(useSharpX)
        useButtonComp:add(usePRoads)
        
        useLayout:addItem(use)
        useLayout:addItem(useButtonComp)
        
        local nbRoadsComp = api.gui.comp.Component.new("ParamsListComp::SliderParam")
        local nbRoadsLayout = api.gui.layout.BoxLayout.new("VERTICAL")
        nbRoadsComp:setLayout(nbRoadsLayout)
        nbRoadsComp:setId("roadtoolbox.nbRoads")
        nbRoadsLayout:setName("ParamsListComp::SliderParam::Layout")
        
        local nbRoadsText = api.gui.comp.TextView.new(_("NB_ROADS"))
        local nbRoadsValue = api.gui.comp.TextView.new(tostring(state.nbRoads))
        local nbRoadsSlider = api.gui.comp.Slider.new(true)
        local nbRoadsSliderLayout = api.gui.layout.BoxLayout.new("HORIZONTAL")
        
        nbRoadsValue:setName("ParamsListComp::SliderParam::SliderLabel")
        
        nbRoadsSlider:setStep(1)
        nbRoadsSlider:setMinimum(2)
        nbRoadsSlider:setMaximum(20)
        nbRoadsSlider:setValue(state.nbRoads, false)
        nbRoadsSlider:setName("Slider")
        
        nbRoadsSliderLayout:addItem(nbRoadsSlider)
        nbRoadsSliderLayout:addItem(nbRoadsValue)
        nbRoadsLayout:addItem(nbRoadsText)
        nbRoadsLayout:addItem(nbRoadsSliderLayout)
        
        local spacingComp = api.gui.comp.Component.new("ParamsListComp::SliderParam")
        local spacingLayout = api.gui.layout.BoxLayout.new("VERTICAL")
        spacingLayout:setName("ParamsListComp::SliderParam::Layout")
        
        spacingComp:setLayout(spacingLayout)
        spacingComp:setId("roadtoolbox.spacing")
        
        local spacingText = api.gui.comp.TextView.new(_("SPACING"))
        local spacingValue = api.gui.comp.TextView.new(setSpacingText(state.distance))
        local spacingSlider = api.gui.comp.Slider.new(true)
        local spacingSliderLayout = api.gui.layout.BoxLayout.new("HORIZONTAL")
        
        spacingValue:setName("ParamsListComp::SliderParam::SliderLabel")
        
        spacingSlider:setStep(1)
        spacingSlider:setMinimum(2)
        spacingSlider:setMaximum(200)
        spacingSlider:setValue(state.distance * 2, false)
        spacingSlider:setName("Slider")
        
        spacingSliderLayout:addItem(spacingSlider)
        spacingSliderLayout:addItem(spacingValue)
        spacingLayout:addItem(spacingText)
        spacingLayout:addItem(spacingSliderLayout)
        
        menuLayout:addItem(useComp)
        menuLayout:addItem(nbRoadsComp)
        menuLayout:addItem(spacingComp)
        
        nbRoadsSlider:onValueChanged(function(value)
            table.insert(state.fn, function()
                nbRoadsValue:setText(tostring(value))
                game.interface.sendScriptEvent("__roadtoolbox__", "nbRoads", {nbRoads = value})
            end)
        
        end)
        
        spacingSlider:onValueChanged(function(value)
            table.insert(state.fn, function()
                spacingValue:setText(setSpacingText(value * 0.5))
                game.interface.sendScriptEvent("__roadtoolbox__", "distance", {distance = value * 0.5})
            end)
        end)
        
        useNo:onToggle(function()
            table.insert(state.fn, function()
                game.interface.sendScriptEvent("__roadtoolbox__", "use", {use = false})
                nbRoadsComp:setVisible(false, false)
                spacingComp:setVisible(false, false)
            end)
        end)
        
        useSharpX:onToggle(function()
            table.insert(state.fn, function()
                game.interface.sendScriptEvent("__roadtoolbox__", "use", {use = 1})
                game.interface.sendScriptEvent("__edgeTool__", "off", {sender = "stb"})
                nbRoadsComp:setVisible(false, false)
                spacingComp:setVisible(false, false)
            end)
        end)
        
        usePRoads:onToggle(function()
            table.insert(state.fn, function()
                game.interface.sendScriptEvent("__roadtoolbox__", "use", {use = 2})
                game.interface.sendScriptEvent("__edgeTool__", "off", {sender = "stb"})
                nbRoadsComp:setVisible(true, false)
                spacingComp:setVisible(true, false)
            end)
        end)
        
        if state.use == 1 then
            useSharpX:setSelected(true, true)
        elseif state.use == 2 then
            usePRoads:setSelected(true, true)
        else
            useNo:setSelected(true, true)
        end
    end
end

local function calcVec(p0, p1, t0, t1)
    local q0 = t0:normalized()
    local q1 = t1:normalized()
    
    local v = p1 - p0
    local length = v:length()
    
    local cos = q0:dot(q1)
    local rad = math.acos(cos)
    if (rad < 0.05) then return q0 * length, q1 * length, p0, p1 end
    -- local hsin = math.sqrt((1 - cos) * 0.5)
    -- local r = 0.5 * length / hsin
    local r = length / math.sqrt(2 - 2 * cos)
    local scale = rad * r
    return q0 * scale, q1 * scale, p0, p1
end

local function searchSharpEdge(map, newId, proposal)
    
    local function connected(node, ...)
        local result = {}
        for _, eid in ipairs(map[node]) do
            if not func.contains({...}, eid) then
                local e = {
                    entity = eid,
                    comp = api.engine.getComponent(eid, api.type.ComponentType.BASE_EDGE),
                    streetEdge = api.engine.getComponent(eid, api.type.ComponentType.BASE_EDGE_STREET)
                }
                if e.comp.node0 == node then
                    table.insert(result, func.with(e, {isBegin = true}))
                elseif e.comp.node1 == node then
                    table.insert(result, func.with(e, {isBegin = false}))
                end
            end
        end
        return result
    end
    
    local function traceBack(result, edge, length)
        local len = coor.new(edge.comp.tangent0):length()
        if (len < length) then
            local dest = edge.isBegin and edge.comp.node1 or edge.comp.node0
            local next = connected(dest, edge.entity, table.unpack(newId))
            if (#next == 1) then
                table.insert(result, edge)
                return traceBack(result, next[1], length - len)
            else
                return nil
            end
        else
            table.insert(result, edge)
            if not result[1].isBegin then
                result = func.rev(func.map(result, function(s) return func.with(s, {isBegin = not s.isBegin}) end))-- Nearest edge must in the correct direction
            end
            return result, length - len
        end
    end
    
    return function(id, vec, length)
        local edges = connected(id, table.unpack(newId))
        local isBackwardTooShort = false
        if #edges > 0 then
            for _, e in ipairs(edges) do
                local vece = e.isBegin
                    and coor.new(e.comp.tangent0)
                    or -coor.new(e.comp.tangent1)
                local cx = vece:dot(vec)
                if cx > 0 then
                    local result, len = traceBack({}, e, length)
                    if result then
                        if len < 0 then
                            local fst, lst = result[1], result[#result]
                            
                            for _, e in ipairs(result) do
                                proposal.streetProposal.edgesToRemove[#proposal.streetProposal.edgesToRemove + 1] = e.entity
                            end
                            
                            local entity = api.type.SegmentAndEntity.new()
                            
                            entity.entity = -fst.entity
                            entity.playerOwned = {player = api.engine.util.getPlayer()}
                            
                            local comp0 = fst.comp
                            local comp1 = lst.comp
                            local streetEdge = fst.streetEdge
                            
                            entity.comp.node0 = fst.isBegin and comp0.node0 or comp0.node1
                            entity.comp.node1 = lst.isBegin and comp1.node1 or comp1.node0
                            
                            local pos0 = coor.new(game.interface.getEntity(entity.comp.node0).position)
                            local pos1 = coor.new(game.interface.getEntity(entity.comp.node1).position)
                            local vec0 = coor.new(fst.isBegin and comp0.tangent0 or comp0.tangent1) * (fst.isBegin and 1 or -1)
                            local vec1 = coor.new(lst.isBegin and comp1.tangent1 or comp1.tangent0) * (lst.isBegin and 1 or -1)
                            
                            local vec0, vec1 = calcVec(pos0, pos1, vec0, vec1)
                            
                            for i = 1, 3 do
                                entity.comp.tangent0[i] = vec0[i]
                                entity.comp.tangent1[i] = vec1[i]
                            end
                            
                            entity.comp.type = comp0.type
                            entity.comp.typeIndex = comp0.typeIndex
                            
                            entity.type = 0
                            entity.streetEdge.streetType = streetEdge.streetType
                            entity.streetEdge.hasBus = streetEdge.hasBus
                            entity.streetEdge.tramTrackType = streetEdge.tramTrackType
                            entity.streetEdge.precedenceNode0 = streetEdge.precedenceNode0
                            entity.streetEdge.precedenceNode1 = streetEdge.precedenceNode1
                            
                            proposal.streetProposal.edgesToAdd[#proposal.streetProposal.edgesToAdd + 1] = entity
                        else
                            isBackwardTooShort = true
                        end
                    else
                        isBackwardTooShort = true
                    end
                end
            end
        end
        return not isBackwardTooShort
    end
end

local buildSharp = function(newSegments, nodes)
    local map = api.engine.system.streetSystem.getNode2StreetEdgeMap()
    
    local newProposal = api.type.SimpleProposal.new()
    
    local pos0 = coor.new(game.interface.getEntity(nodes[1].node).position)
    local pos1 = coor.new(game.interface.getEntity(nodes[2].node).position)
    
    local vec = pos1 - pos0
    local length = vec:length()
    
    local entity = api.type.SegmentAndEntity.new()
    
    local streetEdge = api.engine.getComponent(newSegments[1], api.type.ComponentType.BASE_EDGE_STREET)
    local comp = api.engine.getComponent(newSegments[1], api.type.ComponentType.BASE_EDGE)
    
    entity.entity = -newSegments[1]
    entity.playerOwned = {player = api.engine.util.getPlayer()}
    
    entity.comp.node0 = nodes[1].node
    entity.comp.node1 = nodes[2].node
    
    for i = 1, 3 do
        entity.comp.tangent0[i] = vec[i]
        entity.comp.tangent1[i] = vec[i]
    end
    
    entity.comp.type = comp.type
    entity.comp.typeIndex = comp.typeIndex
    
    entity.type = 0
    entity.streetEdge.streetType = streetEdge.streetType
    entity.streetEdge.hasBus = streetEdge.hasBus
    entity.streetEdge.tramTrackType = streetEdge.tramTrackType
    entity.streetEdge.precedenceNode0 = streetEdge.precedenceNode0
    entity.streetEdge.precedenceNode1 = streetEdge.precedenceNode1
    
    newProposal.streetProposal.edgesToAdd[1] = entity
    for i, seg in ipairs(newSegments) do
        newProposal.streetProposal.edgesToRemove[i] = seg
    end
    
    local searchSharpEdge = searchSharpEdge(map, newSegments, newProposal)
    local check = searchSharpEdge(nodes[1].node, vec, length) and searchSharpEdge(nodes[2].node, -vec, length)
    if check then
        local removeNodes = {}
        for _, edge in ipairs(newProposal.streetProposal.edgesToRemove) do
            local e = api.engine.getComponent(edge, api.type.ComponentType.BASE_EDGE)
            removeNodes[e.node0] = removeNodes[e.node0] and removeNodes[e.node0] + 1 or 1
            removeNodes[e.node1] = removeNodes[e.node1] and removeNodes[e.node1] + 1 or 1
        end
        for _, e in ipairs(newProposal.streetProposal.edgesToAdd) do
            if removeNodes[e.comp.node0] then removeNodes[e.comp.node0] = removeNodes[e.comp.node0] - 1 end
            if removeNodes[e.comp.node1] then removeNodes[e.comp.node1] = removeNodes[e.comp.node1] - 1 end
        end
        for node, n in pairs(removeNodes) do
            if #map[node] - n == 0 then
                newProposal.streetProposal.nodesToRemove[#newProposal.streetProposal.nodesToRemove + 1] = node
            end
        end
        
        local build = api.cmd.make.buildProposal(newProposal, nil, true)
        
        api.cmd.sendCommand(build, function(_) end)
    
    end
end

local buildParallel = function(newSegments)
    local newIdCount = 0
    local newNodes = {}
    local function newId()newIdCount = newIdCount + 1 return -newIdCount end
    local proposal = api.type.SimpleProposal.new()
    
    local check = true
    for _, seg in ipairs(newSegments) do
        check = check and api.engine.entityExists(newSegments[1])
    end
    
    if not check then return end
    
    local streetEdge = api.engine.getComponent(newSegments[1], api.type.ComponentType.BASE_EDGE_STREET)
    
    local streetType = api.res.streetTypeRep.getFileName(streetEdge.streetType):match("res/config/street/(.+.lua)")
    local streetTypeIndex = api.res.streetTypeRep.find(streetType)
    local street = api.res.streetTypeRep.get(streetTypeIndex)
    local streetWidth = street.streetWidth + street.sidewalkWidth * 2
    
    local nbRoads = state.nbRoads
    
    local isOdd = nbRoads % 2 == 0
    local pos = func.filter(
        isOdd and
        func.seq(-nbRoads / 2, nbRoads / 2 - 1) or
        func.seq(-(nbRoads - 1) / 2, (nbRoads - 1) / 2),
        function(pos) return pos ~= 0 end
    )
    for n, seg in ipairs(newSegments) do
        local comp = api.engine.getComponent(seg, api.type.ComponentType.BASE_EDGE)
        
        newNodes[n] = {}
        
        if streetType and streetWidth then
            
            local pos0 = coor.new(game.interface.getEntity(comp.node0).position)
            local pos1 = coor.new(game.interface.getEntity(comp.node1).position)
            local vec0 = coor.xyz(comp.tangent0[1], comp.tangent0[2], comp.tangent0[3])
            local vec1 = coor.xyz(comp.tangent1[1], comp.tangent1[2], comp.tangent1[3])
            
            for i, pos in ipairs(pos) do
                local spacing = pos * (state.distance + streetWidth)
                
                local isBack = pos < 0
                local rot = coor.xyz(0, 0, 1)
                local disp0 = vec0:cross(rot):normalized() * spacing
                local disp1 = vec1:cross(rot):normalized() * spacing
                
                local vec0, vec1, pos0, pos1 = table.unpack(isBack
                    and {calcVec(pos1 + disp1, pos0 + disp0, -vec1, -vec0)}
                    or {calcVec(pos0 + disp0, pos1 + disp1, vec0, vec1)}
                )
                local entity = api.type.SegmentAndEntity.new()
                entity.entity = newId()
                entity.playerOwned = {player = api.engine.util.getPlayer()}
                for i = 1, 3 do
                    entity.comp.tangent0[i] = vec0[i]
                    entity.comp.tangent1[i] = vec1[i]
                end
                
                entity.comp.type = comp.type
                entity.comp.typeIndex = comp.typeIndex
                
                entity.type = 0
                entity.streetEdge.streetType = streetTypeIndex
                entity.streetEdge.hasBus = streetEdge.hasBus
                entity.streetEdge.tramTrackType = streetEdge.tramTrackType
                entity.streetEdge.precedenceNode0 = streetEdge.precedenceNode0
                entity.streetEdge.precedenceNode1 = streetEdge.precedenceNode1
                
                local newNode = function(pos)
                    local node = api.type.NodeAndEntity.new()
                    node.entity = newId()
                    for i = 1, 3 do
                        node.comp.position[i] = pos[i]
                    end
                    proposal.streetProposal.nodesToAdd[#proposal.streetProposal.nodesToAdd + 1] = node
                    return node.entity
                end
                
                local catchNode = function(pos)
                    return pipe.new
                        * game.interface.getEntities({pos = pos:toTuple(), radius = streetWidth * 0.5}, {type = "BASE_NODE"})
                        * pipe.map(game.interface.getEntity)
                        * pipe.filter(function(e) return not func.contains(proposal.streetProposal.nodesToRemove, e.id) end)
                        * pipe.sort(function(e) return (coor.new(e.position) - pos):length() end)
                        * (function(r) return #r > 0 and r[1].id or nil end)
                end
                
                if (not isBack and n == 1) or (isBack and n == #newSegments) then
                    entity.comp.node0 = catchNode(pos0) or newNode(pos0)
                else
                    if not isBack then
                        entity.comp.node0 = newNodes[n - 1][i]
                    else
                        entity.comp.node0 = newNode(pos0)
                        newNodes[n][i] = entity.comp.node0
                    end
                end
                
                if (not isBack and n == #newSegments) or (isBack and n == 1) then
                    entity.comp.node1 = catchNode(pos1) or newNode(pos1)
                else
                    if not isBack then
                        entity.comp.node1 = newNode(pos1)
                        newNodes[n][i] = entity.comp.node1
                    else
                        entity.comp.node1 = newNodes[n - 1][i]
                    end
                end
                proposal.streetProposal.edgesToAdd[#proposal.streetProposal.edgesToAdd + 1] = entity
            end
        
        end
    end
    local build = api.cmd.make.buildProposal(proposal, nil, false)
    api.cmd.sendCommand(build, function(x) end)

end

local script = {
    handleEvent = function(src, id, name, param)
        -- dbg.start("127.0.0.1", 8818)
        if (id == "__edgeTool__" and param.sender ~= "stb") then
            if (name == "off") then
                if (param.sender ~= "autosig2" or param.sender ~= "ptracks") then
                    state.use = false
                end
            end
        elseif (id == "__roadtoolbox__") then
            if (name == "use") then
                state.use = param.use
            elseif (name == "nbRoads") then
                state.nbRoads = param.nbRoads
            elseif (name == "distance") then
                state.distance = param.distance
            elseif (name == "sharp") then
                buildSharp(param.newSegments, param.nodes)
            elseif (name == "parallel") then
                buildParallel(param.newSegments)
            end
        end
    end,
    save = function()
        return state
    end,
    load = function(data)
        if data then
            state.use = data.use or false
            state.distance = data.distance
            state.nbRoads = data.nbRoads or 2
        end
    end,
    guiUpdate = function()
        for _, fn in ipairs(state.fn) do fn() end
        state.fn = {}
    end,
    guiHandleEvent = function(source, name, param)
        if source == "streetBuilder" then
            createWindow()
            if name == "builder.apply" then
                local proposal = param.proposal.proposal
                if
                    state.use == 2
                    and proposal.addedSegments
                    and proposal.new2oldSegments
                    and proposal.removedSegments
                    and #proposal.addedSegments > 0
                    and #proposal.new2oldSegments == 0
                    and #proposal.removedSegments == 0
                then
                    local newSegments = {}
                    for i = 1, #proposal.addedSegments do
                        local seg = proposal.addedSegments[i]
                        if seg.type == 0 then
                            table.insert(newSegments, seg.entity)
                        end
                    end
                    
                    if #newSegments > 0 then
                        game.interface.sendScriptEvent("__roadtoolbox__", "parallel", {newSegments = newSegments})
                    end
                elseif
                    state.use == 1 and
                    proposal.addedSegments and #proposal.addedSegments > 0
                    and proposal.removedSegments and #proposal.addedSegments > #proposal.removedSegments
                then
                    local newSegments = {}
                    local nodes = {}
                    local map = api.engine.system.streetSystem.getNode2StreetEdgeMap()
                    for i = 1, #proposal.addedSegments do
                        local seg = proposal.addedSegments[i]
                        if not proposal.new2oldSegments[seg.entity] then
                            table.insert(newSegments, seg.entity)
                            if not nodes[seg.comp.node0] then nodes[seg.comp.node0] = {} end
                            if not nodes[seg.comp.node1] then nodes[seg.comp.node1] = {} end
                            table.insert(nodes[seg.comp.node0], seg.entity)
                            table.insert(nodes[seg.comp.node1], seg.entity)
                        end
                    end
                    
                    local extNodes = {}
                    
                    for node, edges in pairs(nodes) do
                        if #edges == 1 then
                            table.insert(extNodes, {node = node, isConnected = #edges < #map[node]})
                        end
                    end
                    
                    if (#extNodes == 2 and #func.filter(extNodes, pipe.select("isConnected")) > 0) then
                        game.interface.sendScriptEvent("__roadtoolbox__", "sharp", {newSegments = newSegments, nodes = extNodes})
                    end
                end
            end
        end
    end
}

function data()
    return script
end
