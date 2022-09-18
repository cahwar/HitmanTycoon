local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Utils.Component)
local Knit = require(ReplicatedStorage.Packages.Knit)

local BaseService = Knit.CreateService {
    Name = "BaseService",
    Client = {},
}

function BaseService.Client:TrySelectBase(player: Player, baseObject: Instance)
    local baseClass = Component.FromTag("Base"):FromInstance(baseObject)
    
    if(baseClass == nil) then return false, "{Developer Debug}: No Base Class Found From This Instance" end
    if(baseClass:IsAvaliable() == false) then return false, "This base is no more avaliable, choose another one" end

    baseClass.Owner = player
    
    local playerLeftConnection: RBXScriptConnection = nil
    playerLeftConnection = player.AncestryChanged:Connect(function()
        if(player:IsDescendantOf(game) == true) then return end
        baseClass:Cleanup()
        playerLeftConnection:Disconnect()    
    end)

    return true
end

function BaseService.Client:GetAvaliableBases() return self.Server:GetAvaliableBases() end

function BaseService:CheckBaseAvaliabality(base: {[a]: any?})
    return base:IsAvaliable()
end

function BaseService:GetAvaliableBases()
    local avaliableBases = {}

    for _,base in pairs(Component.FromTag("Base")) do
        if base:IsAvaliable() then table.insert(avaliableBases, base) end
    end

    table.sort(avaliableBases, function(baseA, baseB)
        return tonumber(string.split(baseA.Object.Name, "_")[2]) < tonumber(string.split(baseB.Object.Name, "_")[2])
    end)

    return avaliableBases
end

function BaseService:KnitStart()
end

function BaseService:KnitInit()
end

return BaseService
