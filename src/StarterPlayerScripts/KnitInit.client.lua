local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Utils.Component)
local Knit = require(ReplicatedStorage.Packages.Knit)

Component.LoadComponentInstances(ReplicatedStorage.Components)

for _,v in pairs(ReplicatedStorage:GetDescendants()) do
    if string.match(v.Name, "Controller$") then require(v) end
end

Knit.Start():catch(warn)