-- local dump = require "luadump"
local coor = require "rtb/coor"
local func = require "rtb/func"
local pipe = require "rtb/pipe"

-- local dbg = require("LuaPanda")
local state = {
    use = false,
    window = false,
    distance = 0,
    oneWay = true,
    fn = {}
}

local roadTarget = {
    ["standard/country_x_large_new.lua"] = "standard/country_large_one_way_new.lua",
    ["standard/country_large_new.lua"] = "standard/country_medium_one_way_new.lua",
    ["standard/country_medium_new.lua"] = "standard/country_small_one_way_new.lua",
    ["standard/town_x_large_new.lua"] = "standard/town_large_one_way_new.lua",
    ["standard/town_large_new.lua"] = "standard/town_medium_one_way_new.lua",
    ["standard/town_medium_new.lua"] = "standard/town_small_one_way_new.lua"
}

local setWidth = function(ctrl, width)
    local tRect = ctrl:getContentRect()
    local tSize = api.gui.util.Size.new()
    tSize.h = tRect.h
    tSize.w = width
    ctrl:setGravity(-1, -1)
    ctrl:setMinimumSize(tSize)
end

local setSpacingText = function(spacing)
    return string.format("%0.1f%s", spacing, _("METER"))
end

local createWindow = function()
    local spacingText = api.gui.comp.TextView.new(_("SPACING"))
    local spacingValue = api.gui.comp.TextView.new(setSpacingText(state.distance))
    local spacingSlider = api.gui.comp.Slider.new(true)
    local spacingLayout = api.gui.layout.BoxLayout.new("HORIZONTAL")
    
    spacingSlider:setStep(1)
    spacingSlider:setMinimum(0)
    spacingSlider:setMaximum(100)
    spacingSlider:setValue(state.distance * 2, false)
    setWidth(spacingSlider, 150)

    spacingValue:setGravity(1, -1)
    spacingLayout:setGravity(-1, -1)
    spacingLayout:addItem(spacingText)
    spacingLayout:addItem(spacingValue)
    
    local oneWay = api.gui.comp.CheckBox.new(_("ONE_WAY"), "ui/design/components/checkbox_invalid.tga", "ui/design/components/checkbox_valid.tga")
    oneWay:setSelected(state.oneWay, false)
    
    local comp = api.gui.comp.Component.new("")
    local layout = api.gui.layout.BoxLayout.new("VERTICAL")
    layout:setId("roadtoolbox.layout")
    comp:setLayout(layout)
    
    state.window = api.gui.comp.Window.new(_("TITLE"), comp)
    state.window:setId("roadtoolbox.window")
    layout:addItem(spacingLayout)
    layout:addItem(spacingSlider)
    layout:addItem(oneWay)
    
    spacingSlider:onValueChanged(function(value)
        table.insert(state.fn, function()
            spacingValue:setText(setSpacingText(value * 0.5))
            game.interface.sendScriptEvent("__roadtoolbox__", "distance", {distance = value * 0.5})
        end)
    end)
    
    oneWay:onToggle(function()
        table.insert(state.fn, function() 
            game.interface.sendScriptEvent("__roadtoolbox__", "oneway", {})
        end)
    end)

    state.window:onClose(function()state.window:setVisible(false, false) end)
    
    local mainView = api.gui.util.getById("mainView"):getContentRect().h
    local mainMenuHeight = api.gui.util.getById("mainMenuTopBar"):getContentRect().h + api.gui.util.getById("mainMenuBottomBar"):getContentRect().h
    local x = api.gui.util.getById("roadtoolbox.button"):getContentRect().x
    local y = mainView - mainMenuHeight - state.window:calcMinimumSize().h

    game.gui.window_setPosition("roadtoolbox.window", x, y)
end

local createComponents = function()
    if (not state.useLabel) then
        local label = gui.textView_create("roadtoolbox.lable", _("ROAD_TOOLBOX"))
        local button = gui.button_create("roadtoolbox.button", label)
        
        state.useLabel = gui.imageView_create("roadtoolbox.use.text", "ui/shs/nouse.tga")
        local use = gui.button_create("roadtoolbox.use", state.useLabel)
        
        game.gui.boxLayout_addItem(
            "gameInfo.layout",
            gui.component_create("gameInfo.roadtoolbox.sep", "VerticalLine").id
        )
        game.gui.boxLayout_addItem("gameInfo.layout", "roadtoolbox.button")
        game.gui.boxLayout_addItem("gameInfo.layout", "roadtoolbox.use")
        
        use:onClick(function()
                game.interface.sendScriptEvent("__roadtoolbox__", "use", {})
                game.interface.sendScriptEvent("__edgeTool__", "off", {sender = "stb"})
        end)

        button:onClick(function()
            if state.window then
                if state.use == 2 then
                    state.window:setVisible(not state.window:isVisible(), false)
                else
                    state.window:setVisible(false, false)
                end
            elseif not state.window and state.use == 2 then
                table.insert(state.fn, createWindow)
            end
        end)
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
                result = func.rev(func.map(result, function(s) return func.with(s, {isBegin = not s.isBegin}) end)) -- Nearest edge must in the correct direction
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
    local function newId() newIdCount = newIdCount + 1 return -newIdCount end
    local proposal = api.type.SimpleProposal.new()
    
    local streetEdge = api.engine.getComponent(newSegments[1], api.type.ComponentType.BASE_EDGE_STREET)
    local refType = api.res.streetTypeRep.getFileName(streetEdge.streetType):match("res/config/street/(.+.lua)")
    local ref = api.res.streetTypeRep.get(streetEdge.streetType)
    
    local streetType = state.oneWay and roadTarget[refType] or refType
    local streetTypeIndex = api.res.streetTypeRep.find(streetType)
    local street = api.res.streetTypeRep.get(streetTypeIndex)
    local streetWidth = street.streetWidth + street.sidewalkWidth * 2
    local refWidth = ref.streetWidth + ref.sidewalkWidth * 2

    if (state.distance < refWidth) then
        local segNodes = {}
        local map = api.engine.system.streetSystem.getNode2StreetEdgeMap()
        for _, seg in ipairs(newSegments) do
            local comp = api.engine.getComponent(seg, api.type.ComponentType.BASE_EDGE)
            segNodes[comp.node0] = segNodes[comp.node0] and segNodes[comp.node0] + 1 or 1
            segNodes[comp.node1] = segNodes[comp.node1] and segNodes[comp.node1] + 1 or 1
        end
        local checkNode = function(node)
            if #map[node] == segNodes[node] and not func.contains(proposal.streetProposal.nodesToRemove, node) then
                proposal.streetProposal.nodesToRemove[#proposal.streetProposal.nodesToRemove + 1] = node
            end
        end
        for _, seg in ipairs(newSegments) do
            local comp = api.engine.getComponent(seg, api.type.ComponentType.BASE_EDGE)
            checkNode(comp.node0)
            checkNode(comp.node1)
            proposal.streetProposal.edgesToRemove[#proposal.streetProposal.edgesToRemove + 1] = seg
        end
    end
    
    for n, seg in ipairs(newSegments) do
        local comp = api.engine.getComponent(seg, api.type.ComponentType.BASE_EDGE)

        newNodes[n] = {}
        
        if streetType and streetWidth then
            local spacing = (streetWidth + (state.distance >= 0 and (state.distance + 0.05) or state.distance)) * 0.5
            if spacing <= 0 then
                spacing = 0.25
            end

            local pos0 = coor.new(game.interface.getEntity(comp.node0).position)
            local pos1 = coor.new(game.interface.getEntity(comp.node1).position)
            local vec0 = coor.xyz(comp.tangent0[1], comp.tangent0[2], comp.tangent0[3])
            local vec1 = coor.xyz(comp.tangent1[1], comp.tangent1[2], comp.tangent1[3])
            
            for i, rot in ipairs({coor.xyz(0, 0, 1), coor.xyz(0, 0, -1)}) do
                local disp0 = vec0:cross(rot):normalized() * spacing
                local disp1 = vec1:cross(rot):normalized() * spacing
                local vec0, vec1, pos0, pos1 = table.unpack(i == 1
                    and {calcVec(pos0 + disp0, pos1 + disp1, vec0, vec1)}
                    or {calcVec(pos1 + disp1, pos0 + disp0, -vec1, -vec0)}
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
                
                if (i == 1 and n == 1) or (i == 2 and n == #newSegments) then
                    entity.comp.node0 = catchNode(pos0) or newNode(pos0)
                else
                    if i == 1 then
                        entity.comp.node0 = newNodes[n - 1][i]
                    else
                        entity.comp.node0 = newNode(pos0)
                        newNodes[n][i] = entity.comp.node0
                    end
                end

                if (i == 1 and n == #newSegments) or (i == 2 and n == 1) then
                    entity.comp.node1 = catchNode(pos1) or newNode(pos1)
                else
                    if i == 1 then
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
    api.cmd.sendCommand(build, function(x)  end)
    
end

local script = {
    handleEvent = function(src, id, name, param)
        -- dbg.start("127.0.0.1", 8818)
        if (id == "__edgeTool__" and param.sender ~= "stb") then
            if (name == "off") then
                state.use = false
            end
        elseif (id == "__roadtoolbox__") then
            if (name == "use") then
                if (state.use == false) then
                    state.use = 1
                elseif (state.use == 1) then
                    state.use = 2
                else
                    state.use = false
                end
            elseif (name == "oneway") then
                state.oneWay = not state.oneWay
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
            state.oneWay = data.oneWay
        end
    end,
    guiUpdate = function()
        createComponents()
        
        if (state.use ~= 2 and state.window and state.window:isVisible()) then
            state.window:close()
        end
        
        for _, fn in ipairs(state.fn) do fn() end
        state.fn = {}

        state.useLabel:setImage(
            state.use == 1 and "ui/shs/sharp.tga" or state.use == 2 and "ui/shs/parallel.tga" or "ui/shs/nouse.tga"
    )
    end,
    guiHandleEvent = function(_, name, param)
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
}

function data()
    return script
end
