---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by ThinkPad E475.
--- DateTime: 2019/4/15 11:15
---

local OpenList = require("OpenList")
local CloseList = require("CloseList")
local PathNode = require("PathNode")
-- local config = require("config")

local Astar = {}

-- 地图数据
-- 0:可通行
-- 1:不可通行(障碍物)
-- 2:路径点
Astar.map = nil
-- -- 工作区域信息
-- Astar.work_area = nil
-- -- 公共区域信息
-- Astar.public_area = nil

Astar.girdX = 8 -- 地图x轴大小
Astar.girdY = 8 -- 地图y轴大小
Astar.girdZ = 8 -- 地图z轴大小
-- Astar.openList = nil
-- Astar.closeList = nil

-- Astar.work_area = config.work_area  -- 测试阶段
-- Astar.public_area = {}
-- Astar.public_area.ox=config.work_area.ox
-- Astar.public_area.oy=config.work_area.oy
-- Astar.public_area.oz=config.init_z+1
-- Astar.public_area.sx=config.work_area.sx
-- Astar.public_area.sy=config.work_area.sy
-- Astar.public_area.sz=config.public_sz


--获取最短路径
-- map:地图对象
-- ox,oy,oz:起点坐标
-- dx,dy,dz:终点坐标
-- dir:方向
function Astar:getPath(ox,oy,oz,dx,dy,dz,dir,reverse)
    -- ramc1 = collectgarbage("count")
    -- init
    local openList = OpenList:new()
    local closeList = CloseList:new()
    --
    local pathList = {}
    local originNode = PathNode:new(ox,oy,oz,dir,0,self:calcH(ox,oy,oz,dx,dy,dz))
    openList:add(originNode)

    while true do
        local minFNote = openList:getMinF()
        openList:remove(minFNote)
        closeList:add(minFNote)
        local aroundNotes = self:getNodeAround(minFNote,closeList)
        for k,arouNote in pairs(aroundNotes) do
            if not openList:contains(arouNote) then
                if arouNote.rot==0 or arouNote.rot==1 then
                    arouNote.rot=minFNote.rot
                end
                arouNote.father = minFNote
                local rotPrice = self:getRotatePrice(arouNote,minFNote)
                arouNote:setF(minFNote.g+1+rotPrice, self:calcH(arouNote.x,arouNote.y,arouNote.z,dx,dy,dz))
                openList:add(arouNote)
                if arouNote.x == dx and arouNote.y == dy and arouNote.z == dz then
                    local tempPathList = {}
                    local currNote = arouNote
                    while currNote do
                        table.insert(tempPathList, currNote)
                        -- Astar:setPosInfo(currNote.x, currNote.y, currNote.z, 2)
                        currNote = currNote.father
                    end
                    if reverse then
                        return tempPathList
                    end
                    for i=#tempPathList,1,-1 do
                        table.insert(pathList, tempPathList[i])
                    end
                    -- ramc2 = collectgarbage("count")
                    -- print("寻路内存占用："..(ramc2-ramc1))
                    return pathList
                end
            end
        end
        if openList:isEmpty() then
            break
        end
    end
    return nil
end

-- 获取某坐标位置的数据
function Astar:getPosInfo(x,y,z)
    local cx = (x-(x%self.girdX))/self.girdX
    local cy = (y-(y%self.girdY))/self.girdY
    local cz = (z-(z%self.girdZ))/self.girdZ
    local map = self:getChunk(cx,cy,cz)
    if map then
        return map[(x-cx*self.girdX)+(y-cy*self.girdY)*self.girdX+(z-cz*self.girdZ)*self.girdX*self.girdY]
    end
    return nil
end

function Astar:setPosInfo(x,y,z,info)
    local cx = (x-(x%self.girdX))/self.girdX
    local cy = (y-(y%self.girdY))/self.girdY
    local cz = (z-(z%self.girdZ))/self.girdZ
    local map = self:getChunk(cx,cy,cz)
    if map then
        map[(x-cx*self.girdX)+(y-cy*self.girdY)*self.girdX+(z-cz*self.girdZ)*self.girdX*self.girdY]=info
        return true
    else
        return false
    end
end

function Astar:getChunk(x,y,z)
    return self.map[tostring(x+0)..","..tostring(y+0)..","..tostring(z+0)]
end

function Astar:calcH(x,y,z,dx,dy,dz)
    return 1*math.abs(x-dx)+math.abs(y-dy)+math.abs(z-dz)
end

--获取节点转向成本
-- node1:当前节点
-- node2:父节点
-- 0-5依次为下上北南西东
function Astar:getRotatePrice(node1, node2)
    --if node1.rot==node2.rot then
    --    return 0
    --elseif (node1.rot==2 and node2.rot==4) or (node1.rot==2 and node2.rot==5) or
    --        (node1.rot==3 and node2.rot==4) or (node1.rot==3 and node2.rot==5) or
    --        (node2.rot==2 and node1.rot==4) or (node2.rot==2 and node1.rot==5) or
    --        (node2.rot==3 and node1.rot==4) or (node2.rot==3 and node1.rot==5) then
    --    return 1
    --elseif (node1.rot==2 and node2.rot==3) or (node1.rot==3 and node2.rot==2) or
    --        (node1.rot==4 and node2.rot==5) or (node1.rot==5 and node2.rot==4) then
    --    return 2
    --end
    return 0
end

--检查格子是否符合条件
--忽略超出地图节点、障碍物节点、在closeList当中的节点
function Astar:checkNode(node,closeList)
    local x,y,z = node.x,node.y,node.z
    -- local area = self.work_area
    -- local parea = self.public_area
    -- if not ((x>=area.ox and y>=area.oy and z>=area.oz and x<area.ox+area.sx and y<area.oy+area.sy and z<area.oz+area.sz) or
    --         (x>=parea.ox and y>=parea.oy and z>=parea.oz and x<parea.ox+parea.sx and y<parea.oy+parea.sy and z<parea.oz+parea.sz))
    -- then
    --     return false
    -- end
    local ntype = self:getPosInfo(x,y,z)
    if not ntype then
        return false
    end
    if ntype == 1 then
        return false
    end
    if closeList:contains(node) then
        return false
    end
    return true
end

--获取周围的格子
function Astar:getNodeAround(node,closeList)
    local PNode = PathNode
    local x,y,z = node.x, node.y, node.z
    local nodeList = {
        PNode:new(x, y, z+1, 1),
        PNode:new(x, y, z-1, 0),
        PNode:new(x+1, y, z, 5),
        PNode:new(x-1, y, z, 4),
        PNode:new(x, y+1, z, 2),
        PNode:new(x, y-1, z, 3),
    }
    local newList = {}
    for k,v in pairs(nodeList) do
        if self:checkNode(v,closeList) then
            table.insert(newList, v)
        end
    end
    return newList
end

--打印地图
-- sidex,sidey:地图显示大小
function Astar:printMap(pathList,sizex,sizey,sizez)
    local index = 1
    for z=0,sizez-1 do
        for y=0,sizey-1 do
            for x=0,sizex-1 do
                local node = self:getPosInfo(x,y,z)
                local hasNote = false
                if pathList and index<=#pathList then
                    for k,v in pairs(pathList) do
                        if x==v.x and y==v.y and z==v.z then
                            io.stdout:write(string.format(" %-2d", k))
                            index = index+1
                            hasNote = true
                            break
                        end
                    end
                end
                if not hasNote then
                    if node==0 then
                        io.stdout:write(" - ")
                    elseif node==1 then
                        io.stdout:write(" # ")
                    elseif node==2 then
                        io.stdout:write(" * ")
                    elseif node==3 then
                        io.stdout:write(" ! ")
                    end
                end
            end
            io.stdout:write("\n")
        end
        io.stdout:write("z="..tostring(z).."---------------\n")
    end
end

return Astar