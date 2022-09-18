local ComponentInstance = {}
ComponentInstance.__index = ComponentInstance

function ComponentInstance.new()
    local self = setmetatable({}, ComponentInstance)
    return self
end

function ComponentInstance:Add(instance: Instance, class)
    self[instance] = class
end

function ComponentInstance:FromInstance(instance: Instance)
    for i,v in pairs(self) do
        if (i == instance) then return v end
    end
end

return ComponentInstance