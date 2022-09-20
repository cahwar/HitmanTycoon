-- // Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- // References

local Knit = require(ReplicatedStorage.Packages.Knit)

local Modules = ReplicatedStorage.Modules

local GeneralLibraries = Modules.GeneralLibraries
local MethodsModule = require(GeneralLibraries.MethodsModule)
local GuiModule = require(GeneralLibraries.GuiModule)

-- // Module

local Knit = require(ReplicatedStorage.Packages.Knit)

local RoomBuyController = Knit.CreateController { Name = "RoomBuyController" }

function RoomBuyController:init()
    self.player = Players.LocalPlayer
    self.character = self.player.Character or self.player.CharacterAdded:Wait()
    self.buyBGui = self.player:WaitForChild("PlayerGui"):WaitForChild("BillboardGuis"):WaitForChild("BuyRoom")
end

function RoomBuyController:clearBGui()

end

function RoomBuyController:drawBGui()

end

function RoomBuyController:hideBGui()

end

function RoomBuyController:enbleBGui()

end

function RoomBuyController:KnitStart()
    
end

function RoomBuyController:KnitInit()
    self:init()    
end

return RoomBuyController
