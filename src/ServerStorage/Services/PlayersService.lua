local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)

local PlayersService = Knit.CreateService {
    Name = "PlayersService",
    Client = {},
}

PlayersService.Client.StartBaseSelection = Knit.CreateSignal()

function PlayersService:KnitStart()
    Players.PlayerAdded:Connect(function(player: Player)
        self.Client.StartBaseSelection:Fire(player)
    end)
end

function PlayersService:KnitInit()
    
end

return PlayersService
