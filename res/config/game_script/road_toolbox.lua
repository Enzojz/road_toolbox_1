local dump = require "luadump"
local coor = require "rtb/coor"
local func = require "rtb/func"
local pipe = require "rtb/pipe"

local sutil = require "streetutil"
local vec3 = require "vec3"

local dbg = require("LuaPanda")

local state = {
    use = false,
    windows = {
        window = false,
        distance = false,
        oneWay = false
    },
    showWindow = false,
    distance = 0,
    oneWay = true
}

local roadWidth = {
    country_large_one_way_new = 12 + 4 + 4,
    country_medium_one_way_new = 8 + 4 + 4,
    country_small_one_way_new = 3 + 3 + 3,
    town_large_one_way_new = 12 + 4 + 4,
    town_medium_one_way_new = 8 + 4 + 4,
    town_small_one_way_new = 3 + 3 + 3,
    country_x_large_new = 24 + 4 + 4,
    country_large_new = 16 + 4 + 4,
    country_medium_new = 8 + 4 + 4,
    country_small_new = 6 + 3 + 3,
    town_x_large_new = 24 + 4 + 4,
    town_large_new = 16 + 4 + 4,
    town_medium_new = 8 + 4 + 4,
    town_small_new = 6 + 3 + 3
}

local roadTarget = {
    country_x_large_new = "country_large_one_way_new",
    country_large_new = "country_medium_one_way_new",
    country_medium_new = "country_small_one_way_new",
    town_x_large_new = "town_large_one_way_new",
    town_large_new = "town_medium_one_way_new",
    town_medium_new = "town_small_one_way_new"
}

local showWindow = function()
    local distValue = gui.textView_create("roadtoolbox.distance.value", tostring(state.distance))
    local distAdd = gui.textView_create("roadtoolbox.distance.add.text", "+")
    local distSub = gui.textView_create("roadtoolbox.distance.sub.text", "-")
    local distAddButton = gui.button_create("roadtoolbox.distance.add", distAdd)
    local distSubButton = gui.button_create("roadtoolbox.distance.sub", distSub)
    local distLayout = gui.boxLayout_create("roadtoolbox.distance.layout", "HORIZONTAL")
    distLayout:addItem(distSubButton)
    distLayout:addItem(distValue)
    distLayout:addItem(distAddButton)
    
    local arrow = gui.textView_create("roadtoolbox.distance.oneway.arrow", _("ARROW"))
    local oneWay = gui.textView_create("roadtoolbox.distance.oneway.text", _("ONE_WAY"))
    local oneWayButton = gui.button_create("roadtoolbox.distance.oneway", oneWay)
    distLayout:addItem(arrow)
    distLayout:addItem(oneWayButton)
    
    state.windows.distance = distValue
    state.windows.oneway = oneWay
    
    distAddButton:onClick(function()
        game.interface.sendScriptEvent("__roadtoolbox_", "distance", {step = 1})
    end)
    distSubButton:onClick(function()
        game.interface.sendScriptEvent("__roadtoolbox_", "distance", {step = -1})
    end)
    oneWayButton:onClick(function()
        game.interface.sendScriptEvent("__roadtoolbox_", "oneway", {})
    end)
    
    state.windows.window = gui.window_create("roadtoolbox.window", _("SPACING"), distLayout)
    
    local mainView = game.gui.getContentRect("mainView")
    local mainMenuHeight = game.gui.getContentRect("mainMenuTopBar")[4] + game.gui.getContentRect("mainMenuBottomBar")[4]
    local buttonX = game.gui.getContentRect("roadtoolbox.button")[1]
    local size = game.gui.calcMinimumSize(state.windows.window.id)
    local y = mainView[4] - size[2] - mainMenuHeight
    
    state.windows.window:onClose(function()
        state.windows = {
            window = false,
            distance = false,
            oneWay = false
        }
        state.showWindow = false
    end)
    game.gui.window_setPosition(state.windows.window.id, buttonX, y)
end

local createComponents = function()
    if (not state.button) then
        local label = gui.textView_create("roadtoolbox.lable", _("ROAD_TOOLBOX"))
        state.button = gui.button_create("roadtoolbox.button", label)
        
        state.useLabel = gui.imageView_create("roadtoolbox.use.text", "ui/shs/nouse.tga")
        state.use = gui.button_create("roadtoolbox.use", state.useLabel)
        
        game.gui.boxLayout_addItem(
            "gameInfo.layout",
            gui.component_create("gameInfo.roadtoolbox.sep", "VerticalLine").id
        )
        game.gui.boxLayout_addItem("gameInfo.layout", "roadtoolbox.button")
        game.gui.boxLayout_addItem("gameInfo.layout", "roadtoolbox.use")
        
        state.use:onClick(function()
                -- if state.use then
                --     state.showWindow = false
                -- end
                game.interface.sendScriptEvent("__roadtoolbox_", "use", {})
                game.interface.sendScriptEvent("__edgeTool__", "off", {sender = "stb"})
        end)
        state.button:onClick(function()
            state.showWindow = state.use == 2 and not state.showWindow
        end)
    end
end

local function connected(pos, node, ...)
    local result = {}
    local allEdges = game.interface.getEntities({pos = pos, radius = 100}, {type = "BASE_EDGE", includeData = true})
    for eid, e in pairs(allEdges) do
        if not func.contains({...}, eid) then
            if e.node0 == node then
                table.insert(result, func.with(e, {isBegin = true}))
            elseif e.node1 == node then
                table.insert(result, func.with(e, {isBegin = false}))
            end
        end
    end
    return result
end

local function traceBack(newId)
    local function work(result, edge, length)
        local len = coor.new(edge.node0tangent):length()
        if (len < length) then
            local dest = edge.isBegin and edge.node1 or edge.node0
            local next = connected(edge.isBegin and edge.node1pos or edge.node0pos, dest, edge.id, table.unpack(newId))
            if (#next == 1) then
                -- elseif (#next == 0) then
                --     table.insert(result, edge)
                --     return result, length - len
                table.insert(result, edge)
                return work(result, next[1], length - len)
            else
                return nil
            end
        else
            table.insert(result, edge)
            return result, length - len
        end
    end
    return work
end

local exportEdge = function(pos0, pos1, vec0, vec1)
    local edges = {}
    sutil.addEdgeAutoTangents(
        edges,
        vec3.new(pos0.x, pos0.y, pos0.z),
        vec3.new(pos1.x, pos1.y, pos1.z),
        vec3.new(vec0.x, vec0.y, vec0.z),
        vec3.new(vec1.x, vec1.y, vec1.z)
    )
    return edges
end

local function searchSharpEdge(newId, replace, remove)
    local traceBack = traceBack(newId)
    return function(id, vec, length)
        local node = game.interface.getEntity(id)
        local edges = connected(node.position, id, table.unpack(newId))
        local isBackwardTooShort = false
        if #edges > 0 then
            for _, e in ipairs(edges) do
                local vece = e.isBegin and coor.new(e.node0tangent) or -coor.new(e.node1tangent)
                local cx = vece:dot(vec)
                if cx > 0 then
                    local result, len = traceBack({}, e, length)
                    if result then
                        if len < 0 then
                            local fst, lst = result[1], result[#result]
                            local pos0 = coor.new(fst.isBegin and fst.node0pos or fst.node1pos)
                            local pos1 = coor.new(lst.isBegin and lst.node1pos or lst.node0pos)
                            local vec0 = fst.isBegin and coor.new(fst.node0tangent) or -coor.new(fst.node1tangent)
                            local vec1 = lst.isBegin and coor.new(lst.node1tangent) or -coor.new(lst.node0tangent)
                            
                            for _, e in ipairs(result) do
                                table.insert(remove, e.id)
                            end
                            
                            table.insert(
                                replace.backward,
                                {
                                    edge = exportEdge(pos0, pos1, vec0, vec1),
                                    street = fst.streetType,
                                    hasTram = fst.hasTram,
                                    snap0 = false,
                                    snap1 = true
                                }
                        )
                        else
                            isBackwardTooShort = true
                        end
                    else
                        isBackwardTooShort = true
                    end
                else
                    replace.forward[e.id] = {
                        edge = exportEdge(
                            coor.new(e.node0pos),
                            coor.new(e.node1pos),
                            coor.new(e.node0tangent),
                            coor.new(e.node1tangent)
                        ),
                        street = e.streetType,
                        hasTram = e.hasTram,
                        snap0 = not e.isBegin,
                        snap1 = e.isBegin
                    }
                end
            end
        end
        return not isBackwardTooShort
    end
end

local buildSharp = function(newSegments)
    local newId = func.map(newSegments, pipe.select("id"))
    local replace = {forward = {}, backward = {}}
    local remove = {}
    
    local searchSharpEdge = searchSharpEdge(newId, replace, remove)
    
    local segInfo = {false}
    for _, seg in ipairs(newSegments) do
        if not segInfo[#segInfo] then
            local e = game.interface.getEntity(seg.id)
            segInfo[#segInfo] = {
                edge = seg.edge,
                snap0 = seg.snap0,
                snap1 = seg.snap1,
                length = coor.new(seg.edge.vec0):length(),
                hasTram = e.hasTram,
                street = e.streetType
            }
        else
            segInfo[#segInfo].edge.pos1 = seg.edge.pos1
            segInfo[#segInfo].edge.vec1 = seg.edge.vec1
            segInfo[#segInfo].edge.node1 = seg.edge.node1
            segInfo[#segInfo].length = segInfo[#segInfo].length + coor.new(seg.edge.vec0):length()
            segInfo[#segInfo].snap1 = seg.snap1
        end
        if seg.snap1 then
            table.insert(segInfo, false)
        else
            local conn = connected(seg.edge.pos1, seg.edge.node1, table.unpack(newId))
            if #conn > 0 then
                table.insert(segInfo, false)
            end
        end
    end
    
    segInfo =
        pipe.new
        * segInfo
        * pipe.filter(function(seg) return seg and coor.new(seg.edge.vec1):normalized():dot(coor.new(seg.edge.vec0):normalized()) < 0.999 end)
        * pipe.map(function(seg)
            local pos0, pos1 = coor.new(seg.edge.pos0), coor.new(seg.edge.pos1)
            local vec = pos1 - pos0
            return func.with(seg,
                {
                    edge = func.with(seg.edge,
                        {
                            vec0 = vec:toTuple(),
                            vec1 = vec:toTuple()
                        }
                    ),
                    length = vec:length()
                })
        end)
    if #segInfo == 1 then
        local seg = segInfo[1]
        
        if
            searchSharpEdge(seg.edge.node0, coor.new(seg.edge.vec0), seg.length) and
            searchSharpEdge(seg.edge.node1, -coor.new(seg.edge.vec1), seg.length)
        then
            for id, _ in pairs(replace.forward) do
                if func.contains(remove, id) then
                    replace.forward[id] = false
                else
                    table.insert(remove, id)
                end
            end
            
            for _, e in ipairs(remove) do game.interface.bulldoze(e) end
            
            for _, e in ipairs(newId) do game.interface.bulldoze(e) end
            
            local new = func.map(segInfo,
                function(seg)
                    local vec = (coor.new(seg.edge.pos1) - coor.new(seg.edge.pos0))
                    return func.with(seg, {edge = exportEdge(coor.new(seg.edge.pos0), coor.new(seg.edge.pos1), vec, vec)})
                end
            )
            local replace = func.concat(replace.backward, func.filter(func.values(replace.forward), pipe.noop()))
            local id = game.interface.buildConstruction("sharp_street.con", {new = new, replace = replace}, coor.I())
            game.interface.setPlayer(id, game.interface.getPlayer())
            game.interface.upgradeConstruction(id, "sharp_street.con", {new = new, replace = replace, isFinal = true})
            game.interface.bulldoze(id)
        end
    end
end

local buildParallel = function(newSegments)
    local new = {}
    
    for n, seg in ipairs(newSegments) do
        local e = game.interface.getEntity(seg.id)
        
        local sType = string.match(e.streetType or "", "standard/(.+).lua")
        local streetType = state.oneWay and roadTarget[sType] or sType
        local streetWidth = roadWidth[streetType]
        if streetType and streetWidth then
            local spacing = (streetWidth + (state.distance >= 0 and (state.distance + 0.05) or state.distance)) * 0.5
            if spacing <= 0 then
                spacing = 0.25
            end
            local pos0 = coor.new(seg.edge.pos0)
            local pos1 = coor.new(seg.edge.pos1)
            local vec0 = coor.new(seg.edge.vec0)
            local vec1 = coor.new(seg.edge.vec1)
            
            for i, rot in ipairs({coor.xyz(0, 0, 1), coor.xyz(0, 0, -1)}) do
                local disp0 = vec0:cross(rot):normalized() * spacing
                local disp1 = vec1:cross(rot):normalized() * spacing
                local edge = i == 1
                    and exportEdge(pos0 + disp0, pos1 + disp1, vec0, vec1)
                    or exportEdge(pos1 + disp1, pos0 + disp0, -vec1, -vec0)
                
                table.insert(new,
                    {
                        edge = edge,
                        hasTram = e.hasTram,
                        street = "standard/" .. streetType .. ".lua",
                        snap0 = (i == 1 and n == 1) or (i == 2 and n == #newSegments),
                        snap1 = (i == 1 and n == #newSegments) or (i == 2 and n == 1)
                    }
            )
            end
            
            if (state.distance >= roadWidth[sType]) then
                table.insert(new,
                    {
                        edge = exportEdge(pos0, pos1, vec0, vec1),
                        hasTram = e.hasTram,
                        street = "standard/" .. sType .. ".lua",
                        snap0 = n == 1,
                        snap1 = n == #newSegments
                    }
            )
            end
            game.interface.bulldoze(seg.id)
        end
    end
    
    local id = game.interface.buildConstruction("parallel_street.con", {new = new}, coor.I())
    game.interface.setPlayer(id, game.interface.getPlayer())
    game.interface.upgradeConstruction(id, "parallel_street.con", {new = new, isFinal = true})
    game.interface.bulldoze(id)
end

local script = {
    handleEvent = function(src, id, name, param)
        dbg.start("127.0.0.1", 8818)
        if (id == "__edgeTool__" and param.sender ~= "stb") then
            if (name == "off") then
                state.use = false
            end
        elseif (id == "__roadtoolbox_") then
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
                state.distance = state.distance + param.step
            elseif (name == "sharp") then
                buildSharp(param.newSegments)
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
            if (state.use == 1 and data.use == 2) then
                state.showWindow = true
            end
            state.use = data.use or false
            state.distance = data.distance
            state.oneWay = data.oneWay
        end
    end,
    guiUpdate = function()
        createComponents()
        
        if (state.showWindow and not state.windows.window) then
            showWindow()
        elseif (not state.showWindow and state.windows.window) then
            state.windows.window:close()
        elseif (state.use ~= 2 and (state.windows.window or state.showWindow)) then
            state.windows.window:close()
        end
        
        if state.windows.window then
            state.windows.distance:setText(string.format("%0.1f%s", state.distance, _("METER")))
            state.windows.oneway:setText(state.oneWay and _("ONE_WAY") or _("KEEP"))
        end
        
        state.useLabel:setImage(
            state.use == 1 and "ui/shs/sharp.tga" or state.use == 2 and "ui/shs/parallel.tga" or "ui/shs/nouse.tga"
    )
    end,
    guiHandleEvent = function(_, name, param)
        if name == "builder.apply" then
            local proposal = param.proposal.proposal
            dump()(proposal)
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
                local nodes = {}
                
                for i = 1, #proposal.addedNodes do
                    local node = proposal.addedNodes[i]
                    local id = node.entity
                    nodes[id] = {node.comp.position[1], node.comp.position[2], node.comp.position[3]}
                end
                
                for i = 1, #proposal.addedSegments do
                    local seg = proposal.addedSegments[i]
                    if seg.type == 0 then
                        local node0 = nodes[seg.comp.node0]
                        local node1 = nodes[seg.comp.node1]
                        local snap0 = not node0
                        local snap1 = not node1
                        
                        local edge = {
                            pos0 = node0 or (game.interface.getEntity(seg.comp.node0).position),
                            pos1 = node1 or (game.interface.getEntity(seg.comp.node1).position),
                            vec0 = {seg.comp.tangent0[1], seg.comp.tangent0[2], seg.comp.tangent0[3]},
                            vec1 = {seg.comp.tangent1[1], seg.comp.tangent1[2], seg.comp.tangent1[3]},
                            node0 = seg.comp.node0,
                            node1 = seg.comp.node1
                        }
                        
                        table.insert(newSegments,
                            {
                                id = seg.entity,
                                edge = edge,
                                snap0 = snap0,
                                snap1 = snap1
                            })
                    end
                end
                
                if #newSegments > 0 then
                    game.interface.sendScriptEvent("__roadtoolbox_", "parallel", {newSegments = newSegments})
                end
            elseif
                state.use == 1 and proposal.addedSegments and proposal.addedNodes and #proposal.addedSegments > 0 and
                #proposal.addedNodes > 0
            then
                local nodes = {}
                local nodeCount = {}
                
                local removed = {}
                local added = {}
                
                for i = 1, #proposal.removedSegments do
                    local seg = proposal.removedSegments[i]
                    removed[seg.entity] = seg
                end
                
                for i = 1, #proposal.addedNodes do
                    local node = proposal.addedNodes[i]
                    local id = node.entity
                    nodes[id] = {node.comp.position[1], node.comp.position[2], node.comp.position[3]}
                    nodeCount[id] = {}
                end
                
                for i = 1, #proposal.addedSegments do
                    local seg = proposal.addedSegments[i]
                    added[seg.entity] = seg
                    if seg.type == 0 then
                        if nodes[seg.comp.node0] then
                            table.insert(nodeCount[seg.comp.node0], {seg.entity, true})
                        end
                        if nodes[seg.comp.node1] then
                            table.insert(nodeCount[seg.comp.node1], {seg.entity, false})
                        end
                    end
                end
                
                local triNodes = {}
                for id, nc in pairs(nodeCount) do
                    if #nc == 3 then
                        table.insert(triNodes, id)
                    end
                end
                
                local function trackBack(ref, result, segId, isBegin)
                    local nextNode = isBegin and ref[segId].comp.node1 or ref[segId].comp.node0
                    for id, seg in pairs(ref) do
                        if id ~= segId then
                            if seg.comp.node0 == nextNode then
                                return trackBack(ref,
                                    result
                                    / {
                                        id = segId,
                                        isBegin = isBegin,
                                        node0 = ref[segId].comp.node0,
                                        node1 = ref[segId].comp.node1
                                    },
                                    id, true)
                            elseif seg.comp.node1 == nextNode then
                                return trackBack(ref,
                                    result /
                                    {
                                        id = segId,
                                        isBegin = isBegin,
                                        node0 = ref[segId].comp.node0,
                                        node1 = ref[segId].comp.node1
                                    },
                                    id, false)
                            end
                        end
                    end
                    return {
                        lastNode = nextNode,
                        isLastNodeNew = nodes[nextNode] ~= nil,
                        result = result /
                        {
                            id = segId,
                            isBegin = isBegin,
                            node0 = ref[segId].comp.node0,
                            node1 = ref[segId].comp.node1
                        }
                    }
                end
                
                
                local preProcForSend = function(result)
                    local newSegments = func.map(result,
                        function(r)
                            local seg = added[r.id]
                            
                            local node0 = nodes[seg.comp.node0]
                            local node1 = nodes[seg.comp.node1]
                            local snap0 = not node0
                            local snap1 = not node1
                            
                            local edge = {
                                pos0 = node0 or (game.interface.getEntity(seg.comp.node0).position),
                                pos1 = node1 or (game.interface.getEntity(seg.comp.node1).position),
                                vec0 = {seg.comp.tangent0[1], seg.comp.tangent0[2], seg.comp.tangent0[3]},
                                vec1 = {seg.comp.tangent1[1], seg.comp.tangent1[2], seg.comp.tangent1[3]},
                                node0 = seg.comp.node0,
                                node1 = seg.comp.node1
                            }
                            
                            return {
                                id = seg.entity,
                                edge = edge,
                                snap0 = snap0,
                                snap1 = snap1,
                                isBegin = r.isBegin
                            }
                        end)
                    if #newSegments > 0 then
                        local isRev = not newSegments[1].isBegin
                        if isRev then
                            newSegments = func.map(newSegments,
                                function(seg)
                                    local edge = seg.edge
                                    if seg.isBegin then
                                        edge.pos0, edge.pos1 = edge.pos1, edge.pos0
                                        edge.node0, edge.node1 = edge.node1, edge.node0
                                        edge.vec0, edge.vec1 = (-coor.new(edge.vec1)):toTuple(), (-coor.new(edge.vec0)):toTuple()
                                        snap0, snap1 = snap1, snap0
                                    end
                                    return func.with(seg, {edge = edge})
                                end)
                            newSegments = func.rev(newSegments)
                        else
                            newSegments =
                                func.map(newSegments, function(seg)
                                    local edge = seg.edge
                                    if not seg.isBegin then
                                        edge.pos0, edge.pos1 = edge.pos1, edge.pos0
                                        edge.node0, edge.node1 = edge.node1, edge.node0
                                        edge.vec0, edge.vec1 = (-coor.new(edge.vec1)):toTuple(), (-coor.new(edge.vec0)):toTuple()
                                        snap0, snap1 = snap1, snap0
                                    end
                                    return func.with(seg, {edge = edge})
                                end)
                        end
                        
                        game.interface.sendScriptEvent("__roadtoolbox_", "sharp", {newSegments = newSegments})
                    end
                end
                
                
                if #triNodes == 1 then
                    local node = triNodes[1]
                    local terminalNodes = func.map(
                        nodeCount[node],
                        function(s) return trackBack(added, pipe.new, table.unpack(s)) end
                    )
                    local lastNodeNew = func.filter(terminalNodes, pipe.select("isLastNodeNew"))
                    
                    if #lastNodeNew == 1 then
                        preProcForSend(lastNodeNew[1].result)
                    elseif #lastNodeNew == 0 then
                        local terminalNodes = func.map(terminalNodes,
                            function(n)
                                local nodeId = n.lastNode
                                local lastSeg = n.result[#n.result].id
                                local r = false
                                for _, id in pairs(proposal.new2oldSegments[lastSeg] or {}) do
                                    local seg = removed[id]
                                    if seg.comp.node0 == nodeId then
                                        r = trackBack(removed, pipe.new, id, true)
                                        break
                                    elseif seg.comp.node1 == nodeId then
                                        r = trackBack(removed, pipe.new, id, false)
                                        break
                                    end
                                end
                                return {
                                    result = n.result,
                                    lastNode = n.lastNode,
                                    oldLastNode = r.lastNode or false,
                                    oldResult = r.result
                                }
                            end)
                        local function checkConnection(a, b, c)
                            return terminalNodes[a].lastNode == terminalNodes[b].oldLastNode and
                                terminalNodes[b].lastNode == terminalNodes[a].oldLastNode and
                                terminalNodes[c].oldLastNode ~= terminalNodes[a].lastNode and
                                terminalNodes[c].oldLastNode ~= terminalNodes[b].lastNode
                        end
                        
                        local b =
                            checkConnection(1, 2, 3) and 3 or checkConnection(1, 3, 2) and 2 or
                            checkConnection(2, 3, 1) and 1 or
                            false
                        if b then
                            preProcForSend(terminalNodes[b].result)
                        end
                    end
                end
            end
        end
    end
}

function data()
    return script
end
