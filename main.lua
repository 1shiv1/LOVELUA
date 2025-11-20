local particle = require("Particle")
local Vector2 = require("Vector2")
local cfg = require("cfg")
local utils = require("utils")

local ActiveParticles = {}

math.randomseed(os.time())

local WinWidth = cfg.window.width
local WinHeight = cfg.window.height

local function sleep(seconds)
    local start_time = os.clock()
    while os.clock() - start_time < seconds do
        -- busy-wait
    end
end

function love.load()
    love.window.setMode(WinWidth, WinHeight, {resizable=false, vsync=true})
    love.window.setTitle(cfg.window.title)

    for i = 1, cfg.general.particleCount do
        local p = particle.new(
            Vector2.new(math.random(0,WinWidth), math.random(0,WinHeight)),
            7,
            Vector2.new((math.random(0,15)-7.5),(math.random(0,15)-7.5)),
            0.6, --default elasticity
            false
        )
        table.insert(ActiveParticles, p)
    end
end

local function UnwrapGridKey(key)
    local xy = {x = "", y = ""}  -- use strings for accumulation
    local Select = "x"

    for i = 1, #key do
        local c = key:sub(i,i)
        if c == "," then
            Select = "y"
        else
            xy[Select] = xy[Select] .. c
        end
    end

    return Vector2.new(tonumber(xy.x), tonumber(xy.y))
end

local function NarrowPhase(a, b)
    local dist = (a.Position - b.Position):Magnitude()
    local radiusSum = a.radius + b.radius
    return dist < radiusSum
end

local function uncollide(a,b,n)
    n = n or (a.Position - b.Position):Unit()
    local dist = (a.Position - b.Position):Magnitude()
    local overlap = (a.radius + b.radius) - dist
    if overlap > 0 then
        a.Position = a.Position + n * (overlap / 2)
        b.Position = b.Position - n * (overlap / 2)

    end
end

local function BroadPhase(grid)
    for key, cell in pairs(grid) do
        local NeighbhorInclusion = {}
        local keyVec = UnwrapGridKey(key)

        for dx = -1, 1 do
            for dy = -1, 1 do
                local neighborKey = (keyVec.x + dx) .. "," .. (keyVec.y + dy)
                local neighbor = grid[neighborKey]
                if neighbor then
                    utils.MergeArryInto(NeighbhorInclusion, neighbor)
                end
            end
        end

        if NeighbhorInclusion == cell then
            print("Neighbhored and cell were the same")
        end

        for i = 1, #NeighbhorInclusion do --for every object in cells
            local a = NeighbhorInclusion[i] --object in cells

            for j = i + 1, #NeighbhorInclusion do 
            --[[check every object after current. 
            Dont have to check backwards, because 
            if b->a then a's forward check wouldve 
            caught b]]
                local b = NeighbhorInclusion[j] 

                if NarrowPhase(a, b) then
                    a.Color = {0,0,1}
                    b.Color = {0,0,1}

                    local n = (a.Position - b.Position):Unit()
                    local vRel = a.Velocity - b.Velocity
                    local proj = vRel:Dot(n)
                    
                    uncollide(a, b, n)
                    a:GetGrid()
                    b:GetGrid()
                    --calulcate how much to move to make them no collide
                    

                    a.Velocity = a.Velocity - n * proj * (a.Elasticity)
                    b.Velocity = b.Velocity + n * proj * (b.Elasticity)
                end
            end
        end
    end
end

local function AssembleGrid()
    local grid = {}
    local GCCx, GCCy = WinWidth / cfg.physics.BroadphaseGridSize, WinHeight / cfg.physics.BroadphaseGridSize

    local cols = math.floor(WinWidth / cfg.physics.BroadphaseGridSize)
    local rows = math.floor(WinHeight / cfg.physics.BroadphaseGridSize)

    for x = 0, cols - 1 do
        for y = 0, rows - 1 do
            local key = x .. "," .. y
            if not grid[key] then
                grid[key] = {} -- ensures every cell exists
            end
        end
    end
    
    for _, obj in ipairs(ActiveParticles) do
        local gx, gy = obj.Grid.x, obj.Grid.y

        local maxGx = math.floor((WinWidth) / cfg.physics.BroadphaseGridSize)
        local maxGy = math.floor((WinHeight) / cfg.physics.BroadphaseGridSize)
        gx = math.max(0, math.min(gx, maxGx))
        gy = math.max(0, math.min(gy, maxGy))

        obj.Color = {(GCCx - gx) / GCCx, 0, (GCCy - gy) / GCCy}

        local key = gx .. "," .. gy
        table.insert(grid[key], obj)
    end

    return grid
end

local function inMouse()
    local affected = {}
    local x, y = love.mouse.getPosition()

    for _, p in pairs(ActiveParticles) do
        local r = 110
        local dx = p.Position.x - x
        local dy = p.Position.y - y
        local distanceSquared = dx * dx + dy * dy

        if distanceSquared <= r * r then
            table.insert(affected, p)
        end
    end

    return affected
end

local function MousePushPull(factor)
    local x, y = love.mouse.getPosition()
    local affected = inMouse()

    for _, p in pairs(affected) do 
        local r = 110
        local dx = p.Position.x - x
        local dy = p.Position.y - y
        local distanceSquared = dx * dx + dy * dy

        if distanceSquared <= r * r then
            p.Velocity = Vector2.new(dx/factor,dy/factor)
            p.AttMouse = true
        end
    end
end



function love.update(dt)
    for _, p in pairs(ActiveParticles) do
        p:Update(dt, ActiveParticles)
        p:GetGrid()
    end

    if love.mouse.isDown(1) then  -- 1 = left, 2 = right, 3 = middle
        MousePushPull(-10)
    end

    if love.mouse.isDown(2) then  -- 1 = left, 2 = right, 3 = middle
        MousePushPull(15)
    end

    for i = 1, cfg.physics.BroadphasePasses do
        local grid = AssembleGrid()
        BroadPhase(grid)
    end
end

function love.draw()
    local x, y = love.mouse.getPosition()

    for _, p in pairs(ActiveParticles) do
        p:Draw()
    end

    for _, p in pairs(ActiveParticles) do
        if p.AttMouse then
            local x, y = love.mouse.getPosition()
            love.graphics.setColor(1,0.5,0)
            love.graphics.line(x, y, p.Position.x, p.Position.y)
        end
        p.AttMouse = false
    end

    love.graphics.setColor(1,0.4,0,0.25)
    love.graphics.circle("fill", x, y, 110)
end