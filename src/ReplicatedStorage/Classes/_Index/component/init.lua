local CollectionService = game:GetService("CollectionService")

local Component = {}
Component.__index = Component

Component.ComponentInstances = {}

--[[
    Component - base class for components managing,
    Component Instance - union of component objects, main tag section - ex. many Axes,
    Component Object - object of a Component Instance - ex. single Axe
]]--

function Component.LoadComponentInstances(componentsFolder: Folder)
    for _,componentClass in pairs(componentsFolder:GetDescendants()) do
        if (typeof(componentClass) ~= "Instance" or componentClass:IsA("ModuleScript") == false) then continue end

        local componentClassInner = require(componentClass)
        if (componentClassInner.Tag == nil) then continue end

        if (Component.ComponentInstances[componentClass] == nil) then
            Component.ComponentInstances[componentClassInner.Tag] = require(script["component-instance"]).new()
        end

        for _,v in pairs(CollectionService:GetTagged(componentClassInner.Tag)) do
            Component.ComponentInstances[componentClassInner.Tag]:Add(v, componentClassInner.new(v))
        end

        CollectionService:GetInstanceAddedSignal(componentClassInner.Tag):Connect(function(instance: Instance)
            Component.ComponentInstances[componentClassInner.Tag]:Add(instance, componentClassInner.new(instance))
        end)

        CollectionService:GetInstanceRemovedSignal(componentClassInner.Tag):Connect(function(instance: Instance)
            for i,v in pairs(Component.ComponentInstances[componentClassInner.Tag]) do
                if (i == instance) then
                    v:Destroy()
                    Component.ComponentInstances[componentClassInner.Tag][i] = nil
                end
            end
        end)
    end
end

function Component.FromTag(tag: string)
    for i,v in pairs(Component.ComponentInstances) do
        if (i == tag) then return v end
    end
end

return Component