--// Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--// References

local Modules = ReplicatedStorage.Modules

local GeneralLibraries = Modules.GeneralLibraries
local MethodsModule = require(GeneralLibraries.MethodsModule)
local GuiModule = require(GeneralLibraries.GuiModule)

local LuaExtensions = Modules.LuaExtensions
local QueueClass = require(LuaExtensions.Queue)

local Camera = workspace.CurrentCamera
local Player = Players.LocalPlayer

--// Variables

local Connections = {}
local Bobbles = {}

local FOVQueue = QueueClass.New()

--// Functions

local function FindBobbleByName(Name: string) : Bobble
	local Bobble = Bobbles[Name]
	
	if not Bobble then
		warn("Bobble with this name was not found:", Name or "|NULL|")
		return false
	end
	
	return Bobble
end

--// Module

local CameraModule = {}

export type Bobble = {ChangeIntensity: (string, number) -> nil, Stop: (number) -> nil}

function CameraModule.StartCameraBobbling(BobbleName: string, ValuesCalculationFunction: () -> {[a]: number}, Values: {[a]: number}, BobblingDuration: number, BobblingAxis: string, ClampFunction: (number) -> number, StoppingDuration: number, StartingDuration: number)
	if Bobbles[BobbleName] ~= nil then
		warn("There is already a bobble with this name:", BobbleName or "|NULL|")
		return false
	end
	
	local Character = Player.Character or Player.CharacterAdded:Wait()
	local Humanoid: Humanoid = Character:WaitForChild("Humanoid")
	
	local BobbleInfo = {
		Connections = {};
		
		BobblingHeightIntensity = StartingDuration and 0 or 1;
		BobblingSpeedIntensity = 1;
		
		StartTime = tick();
		IsPaused = false;
		
		ChangeIntensity = function(self, IntensityToChange: string, ValueToSet: number)
			if IntensityToChange == "Height" then self.BobblingHeightIntensity = ValueToSet
			elseif IntensityToChange == "Speed" then self.BobblingSpeedIntensity = ValueToSet end
		end,
		
		Stop = function(self)
			MethodsModule.RepeatActionPereodically(self.BobblingHeightIntensity, 0, StoppingDuration or 2, function(SetValue) self.BobblingHeightIntensity = SetValue end, function()
				MethodsModule.ClearConnections(self.Connections)
				Bobbles[BobbleName] = nil
			end)
		end,
		
		ChangePause = function(self, Statement: boolean)
			self.IsPaused = Statement
		end,
	}
	
	BobbleInfo.Connections[MethodsModule.GetTableLength(BobbleInfo.Connections) + 1] = Humanoid.Died:Connect(function()
		BobbleInfo:Stop()
	end)
	
	BobbleInfo.Connections[MethodsModule.GetTableLength(BobbleInfo.Connections) + 1] = RunService.RenderStepped:Connect(function()
		if BobbleInfo.IsPaused == true then return end
		
		Values = ValuesCalculationFunction ~= nil and ValuesCalculationFunction() or Values
		local SinHeight, SinSpeed, CosHeight, CosSpeed = table.unpack(Values)
		
		local SinWave = (math.sin(tick() * (SinSpeed * BobbleInfo.BobblingSpeedIntensity)) * (SinHeight * BobbleInfo.BobblingHeightIntensity)) / 10
		local CosWave = (math.sin(tick() * (CosSpeed * BobbleInfo.BobblingSpeedIntensity)) * (CosHeight * BobbleInfo.BobblingHeightIntensity)) / 10
		
		if ClampFunction then
			SinWave = ClampFunction(SinWave)
			CosWave = ClampFunction(CosWave)
		end
		
		local Angle: CFrame = BobblingAxis == "XY" and CFrame.Angles(math.rad(SinWave), math.rad(CosWave), 0) or BobblingAxis == "XZ" and CFrame.Angles(math.rad(SinWave), 0, math.rad(CosWave))
		Camera.CFrame = Camera.CFrame * Angle
		
		if BobblingDuration ~= nil and tick() - BobbleInfo.StartTime >= BobblingDuration then
			BobbleInfo:Stop()
		end
	end)
	
	if StartingDuration then
		MethodsModule.RepeatActionPereodically(BobbleInfo.BobblingHeightIntensity, 1, StartingDuration, function(SetValue) BobbleInfo.BobblingHeightIntensity = SetValue end)
	end
	
	Bobbles[BobbleName] = BobbleInfo
end

function CameraModule.StopCameraBobbling(BobbleName: string)
	local BobbleInfo = FindBobbleByName(BobbleName)
	if BobbleInfo then BobbleInfo:Stop() end
end

function CameraModule.ChangeBobbleIntensity(BobbleName: string, IntensityToChange: string, ValueToSet)
	local BobbleInfo = FindBobbleByName(BobbleName)
	if BobbleInfo then BobbleInfo:ChangeIntensity(IntensityToChange, ValueToSet) end
end

function CameraModule.EnableShiftLock()
	if Connections.ShiftLock ~= nil then
		CameraModule.DisableShiftlock()
		repeat task.wait() until Player:GetAttribute("ShiftLocked") == nil
	end

	local Character = Player.Character or Player.CharacterAdded:Wait()
	local Humanoid: Humanoid = Character:WaitForChild("Humanoid")

	Connections.ShiftLock = RunService.RenderStepped:Connect(function(DeltaTime)
		local HumanoidRootPartCFrame = Humanoid.RootPart.CFrame

		local _, CameraRotationX, _ = Camera.CFrame.Rotation:ToEulerAnglesYXZ()
		local CFrameToSet = CFrame.new(HumanoidRootPartCFrame.Position) * CFrame.Angles(0, CameraRotationX, 0)

		local _, CharacterRotationX, _ = HumanoidRootPartCFrame.Rotation:ToEulerAnglesYXZ()
		local _, CFrameToSetRotationX, _ = CFrameToSet:ToEulerAnglesYXZ()

		if MethodsModule.Approximately(math.deg(CameraRotationX), math.deg(CharacterRotationX), 4) == true then return end

		Humanoid.RootPart.CFrame = HumanoidRootPartCFrame:Lerp(CFrameToSet, DeltaTime * 25)
	end)
end

function CameraModule.DisableShiftlock()
	Player:SetAttribute("ShiftLocked", nil)
end

function CameraModule.ChangeFOV(FovToSet: number, ChangeDuration: number, ChangeSessionName: string)
	local function ChangeFov()
		local StartFov = Camera.FieldOfView
		if StartFov == FovToSet then return end
		
		Camera:SetAttribute("FovLerp", true)
		MethodsModule.RepeatActionPereodically(StartFov, FovToSet, ChangeDuration, function(CurrentFov)
			Camera.FieldOfView = CurrentFov
		end, function()
			Camera:SetAttribute("FovLerp", nil)
		end)
	end
		
	if FOVQueue:FindMember(ChangeSessionName) then return end
	
	FOVQueue:Enqueue({Name = ChangeSessionName, Action = ChangeFov})
	
	task.spawn(function()
		while MethodsModule.GetTableLength(FOVQueue.Members) > 0 do
			if Camera:GetAttribute("FovLerp") ~= nil then repeat task.wait() until Camera:GetAttribute("FovLerp") == nil end
			FOVQueue:Dequeue().Action()
		end
	end)
end

function CameraModule.ForceCameraTransition(OutZDistance: number, InZDistance: number, MaxYDistance, FadeScreen: boolean, FadeTransparency: number, FadeDisplayOrder: number, FadeDuration: number, Actions: {[a]: () -> nil}, StartDuration: number, EndDuration: number)
	OutZDistance = OutZDistance or 120; InZDistance = InZDistance or -OutZDistance; MaxYDistance = MaxYDistance or 20; EndDuration = EndDuration or 1.4
	
	local StartCameraCFrame = Camera.CFrame
	
	local OutCFrameToSet = StartCameraCFrame:ToWorldSpace(CFrame.new(Vector3.new(0, MaxYDistance, OutZDistance)))
	local InCFrameToSet = StartCameraCFrame:ToWorldSpace(CFrame.new(Vector3.new(0, -MaxYDistance, InZDistance)))
	
	local FirstTween = MethodsModule.Tween(Camera, {CFrame = OutCFrameToSet}, TweenInfo.new(StartDuration or 1.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
	local SecondTween = MethodsModule.Tween(Camera, {CFrame = InCFrameToSet}, TweenInfo.new(EndDuration or 1.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In))
	
	local StartFadeAction, MiddleFadeAction, EndFadeAction, MiddleTransitionAction, EndTransitionAction = table.unpack(Actions)
	
	FirstTween.Completed:Connect(function()
		local Event = MiddleTransitionAction ~= nil and MiddleTransitionAction() or nil		
		if Event then Event:Connect(function() SecondTween:Play() end) else SecondTween:Play() end
		
		if EndTransitionAction then SecondTween.Completed:Connect(EndTransitionAction) end
		if not FadeScreen then return end
		
		task.delay(EndDuration / 1.5, function()
			GuiModule.FadeScreen(FadeTransparency, FadeDisplayOrder, FadeDuration, table.pack(StartFadeAction, MiddleFadeAction, EndFadeAction))
		end)
	end)
	
	FirstTween:Play()
end

return CameraModule