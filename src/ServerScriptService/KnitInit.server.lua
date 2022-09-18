local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Component = require(ReplicatedStorage.Utils.Component)
local Knit = require(ReplicatedStorage.Packages.Knit)

Component.LoadComponentInstances(ServerStorage.Components)

for _,v in pairs(ServerStorage:GetDescendants()) do
    if string.match(v.Name, "Service$") then require(v) end
end

Knit.Start():catch(warn)