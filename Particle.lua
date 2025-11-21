local Particle = {}

local Vector2 = require("Vector2")
local utils = require("utils")
local cfg = require("cfg")

local WinWidth = cfg.window.width
local WinHeight = cfg.window.height

Particle.__index = Particle

function Particle.new(Position, radius, vel, Elasticity, Anchored, Color)
    local self = setmetatable({}, Particle)

    self.Position = Position or Vector2.zero()
    self.LastPos = self.Position
    self.radius = radius or 10
    self.Velocity = vel or Vector2.zero()
    self.Anchored = Anchored or false
    self.LocalGravityModifier = nil
    self.Friction = 0.05
    self.Color = Color or {0,0,1}
    self.AttMouse = false
    
    self:GetGrid()

    if Elasticity then
        self.Elasticity = math.max(0, math.min(1, Elasticity))
    else
        self.Elasticity = 0.4
    end

    return self
end

function Particle:GetGrid()
    local gridSize = cfg.physics.BroadphaseGridSize

    local gx = math.floor(self.Position.x / gridSize)
    local gy = math.floor(self.Position.y / gridSize)

    self.Grid = Vector2.new(gx, gy)
    return self.Grid
end


function Particle:Update(dt, activeObjects)
    if not self.Anchored then
        local g = self.LocalGravityModifier or cfg.physics.gravity
        self.LastPos = self.Position

        local lastpos = self.Position
        self.Velocity = self.Velocity + Vector2.new(0, g)
        self.Position = self.Velocity + self.Position

        local r = self.radius
        --clamp after deciding to flip vels, because clamping before will prevent the statements below
        if self.Position.y > WinHeight-r or self.Position.y < r then 
            self.Position = utils.Clamp(self.Position, r, WinHeight-r)
            self.Velocity = Vector2.new(
                self.Velocity.x,
                self.Velocity.y * -1 * self.Elasticity
            ) * (1-self.Friction) * (dt * 60)
        elseif self.Position.x > WinWidth-r or self.Position.x < r then 
            self.Position = utils.Clamp(self.Position, r, WinWidth-r)
            self.Velocity = Vector2.new(
                self.Velocity.x * -1 * self.Elasticity,
                self.Velocity.y
            ) * (1-self.Friction) * (dt * 60)
        end
        
        self:GetGrid()
    end
end

function Particle:Draw()
    love.graphics.setColor(self.Color)
    love.graphics.circle("fill", self.Position.x, self.Position.y, self.radius)
end

return Particle