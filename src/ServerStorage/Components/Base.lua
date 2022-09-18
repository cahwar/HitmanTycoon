local Base = {}
Base.__index = Base

Base.Tag = "Base"
Base.Bases = {}

function Base.new(object: Instance)
    local self = setmetatable({}, Base)
    
    self.Owner = nil
    self.Index = tonumber(string.split(object.Name, "_")[2])
    self.Object = object

    table.insert(Base.Bases, self)

    return self
end

function Base:FromIndex(index: number)
    for _,v in pairs(Base.Bases) do
        if(v.Index == index) then return v end
    end
end

function Base:IsAvaliable()
    return self.Owner == nil
end

function Base:Cleanup()
    self.Owner = nil
    -- // Enable Doors, etc...
end

function Base:Destroy()
    
end

return Base
