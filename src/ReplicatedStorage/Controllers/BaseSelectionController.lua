local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // References

local Knit = require(ReplicatedStorage.Packages.Knit)

local Modules = ReplicatedStorage.Modules

local GeneralLibraries = Modules.GeneralLibraries
local MethodsModule = require(GeneralLibraries.MethodsModule)
local CameraModule = require(GeneralLibraries.CameraModule)
local GuiModule = require(GeneralLibraries.GuiModule)

-- // Module

local BaseSelectionController = Knit.CreateController { Name = "BaseSelectionController" }

function BaseSelectionController:init()
    self.player = Players.LocalPlayer
    self.character = self.player.Character or self.player.CharacterAdded:Wait()
    self.camera = workspace.CurrentCamera

    local playerGui = self.player:WaitForChild("PlayerGui")
    self.baseSelectionGui = playerGui:WaitForChild("BaseSelectionGui")
    
    self.previousButton = self.baseSelectionGui:WaitForChild("Previous"):FindFirstChildWhichIsA("ImageButton")
    self.nextButton = self.baseSelectionGui:WaitForChild("Next"):FindFirstChildWhichIsA("ImageButton")
    self.selectButton = self.baseSelectionGui:WaitForChild("Select"):FindFirstChildWhichIsA("ImageButton")

    self.currentBaseIndex = 1; self.currentBase = nil
end

function BaseSelectionController:tweenCamera()
    local baseObject: Model | Part = self.currentBase.Object
    
    local baseSize: Vector3 = baseObject:IsA("Model") and baseObject:GetExtentsSize() or baseObject.Size
    local maxExtentsSize = math.max(baseSize.X, baseSize.Y, baseSize.Z)

    local baseCFrame: CFrame = baseObject:IsA("Model") and baseObject:GetPivot() or baseObject.CFrame
    local basePosition = baseCFrame.Position

    local cFrameToSet = CFrame.new(basePosition + baseCFrame.LookVector * maxExtentsSize * 1.05 + Vector3.new(0, 10, 0), basePosition)
    MethodsModule.Tween(self.camera, {CFrame = cFrameToSet}, TweenInfo.new(.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)):Play()
end

function BaseSelectionController:moveToCurrentBase()
    self.currentBase = self.avaliableBases[self.currentBaseIndex]
    self:tweenCamera()
end

function BaseSelectionController:getAvaliableBases()
    return self.BaseService:GetAvaliableBases():andThen(function(avaliableBases)
        self.avaliableBases = avaliableBases
    end)
end

function BaseSelectionController:moveToAnotherBase(direction: number)
    self:getAvaliableBases():andThen(function()
        if(self.avaliableBases[self.currentBaseIndex + direction] ~= nil) then self.currentBaseIndex += direction
        else self.currentBaseIndex = direction == 1 and 1 or #self.avaliableBases end
        self:moveToCurrentBase()
    end)
end

function BaseSelectionController:confirmSelection()
    self.BaseService:TrySelectBase(self.currentBase.Object):andThen(function(result: boolean, errorLog: string)
        if(result == true) then self:finishSession(); return end
        if(errorLog ~= nil) then GuiModule.CreateTextNotification("<font color='rgb(215, 22, 22)'>"..errorLog.."</font>", 3) end
        self:moveToAnotherBase(1)
    end)
end

function BaseSelectionController:finishSession()
    if(self.maid ~= nil) then self.maid:Destroy() end

    CameraModule.ForceCameraTransition(120, -120, 0, true, 0, 3, 2, {
        nil, function()
            self.baseSelectionGui:Destroy()
            self.camera.CameraType = Enum.CameraType.Custom
            self.character:PivotTo(CFrame.new(self.currentBase.Object:GetPivot().Position + Vector3.new(0, 5, 0)))				
        end,
    }, .6, .5)
end

function BaseSelectionController:launchSession()
    self.maid = require(ReplicatedStorage.Packages.Maid).new()

    self.camera.CameraType = Enum.CameraType.Scriptable
    self.maid:GiveTask(self.camera:GetPropertyChangedSignal("CameraType"):Connect(function() self.camera.CameraType = Enum.CameraType.Scriptable end))

    self.character.PrimaryPart.Anchored = true
    self.maid:GiveTask(function() self.character.PrimaryPart.Anchored = false end)

    self.maid:GiveTask(self.nextButton.MouseButton1Click:Connect(function()
        self:moveToAnotherBase(1)
    end))

    self.maid:GiveTask(self.previousButton.MouseButton1Click:Connect(function()
        self:moveToAnotherBase(-1)
    end))

    self.maid:GiveTask(self.selectButton.MouseButton1Click:Connect(function()
        self:confirmSelection()
    end))

    self:getAvaliableBases():andThen(function()
        self.baseSelectionGui.Enabled = true
        self:moveToCurrentBase()
    end)
end

function BaseSelectionController:KnitStart()
    self.BaseService = Knit.GetService("BaseService")

    Knit.GetService("PlayersService").StartBaseSelection:Connect(function()
        GuiModule.FadeScreen(0, 5, 3, {nil, function() self:launchSession() end})
    end)
end

function BaseSelectionController:KnitInit()
    self:init()
end

return BaseSelectionController