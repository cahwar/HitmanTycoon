--// Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--// References

local Modules = ReplicatedStorage.Modules

local GeneralLibraries = Modules.GeneralLibraries
local MethodsModule = require(GeneralLibraries.MethodsModule)

local AdvancedModules = Modules.AdvancedModules
local RemoteCommunicator = require(AdvancedModules.RemoteCommunicator)

local GoreCacheFolder = workspace:FindFirstChild("GoreCache") or MethodsModule.Instantiate("Folder", "GoreCache", nil, workspace)

--// Functions

local function GetDropPosition(Character: Model, OriginPosition: Vector3, EndPosition: Vector3, FilterInstances)
	FilterInstances = FilterInstances or {Character, GoreCacheFolder}
	
	local NewRaycastParams = RaycastParams.new()
	NewRaycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	NewRaycastParams.FilterDescendantsInstances = FilterInstances
	
	local RaycastResult = MethodsModule.Raycast(OriginPosition, EndPosition, NewRaycastParams)
	if RaycastResult.Instance then		
		local ModelAncestor = RaycastResult.Instance:FindFirstAncestorWhichIsA("Model")
		if ModelAncestor and Players:GetPlayerFromCharacter(ModelAncestor) then
			table.insert(FilterInstances, ModelAncestor)
			return GetDropPosition(Character, OriginPosition, EndPosition, FilterInstances)			
		end		
		
		local ToolAncestor = RaycastResult.Instance:FindFirstAncestorWhichIsA("Tool") 
		if ToolAncestor then
			table.insert(FilterInstances, ToolAncestor)
			return GetDropPosition(Character, OriginPosition, EndPosition, FilterInstances)					
		end		
		
		return RaycastResult.Position
	end
	
	return nil
end

--// Module

local GoreModule = {}

function GoreModule.CreateBloodTrail(StartPosition: Vector3, EndPosition: Vector3)
	local Part = MethodsModule.Instantiate("Part", "Blood_Trail", nil, GoreCacheFolder)
	local Attachment0, Attachment1 = Instance.new("Attachment", Part), Instance.new("Attachment", Part); Attachment1.CFrame = Attachment0.CFrame:ToWorldSpace(CFrame.new(Vector3.new(0, 0, -.5)))
	local Trail = Instance.new("Trail", Part)
	
	Part.Position = StartPosition
	Part.Size = Vector3.new(1, 1, 1)
	Part.Transparency = 1
	Part.Anchored = true
	Part.CanCollide = false

	Trail.WidthScale = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(.4, .25), NumberSequenceKeypoint.new(1, 0)})
	Trail.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
	Trail.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(106, 0, 1)), ColorSequenceKeypoint.new(0.4, Color3.fromRGB(72, 0, 1)), ColorSequenceKeypoint.new(1, Color3.fromRGB(98, 0, 1))})
	Trail.FaceCamera = true; Trail.Attachment0 = Attachment0; Trail.Attachment1 = Attachment1; Trail.Lifetime = .35
	
	for I = 0, 1, .05 do
		Part.Position = MethodsModule.GetBezier(StartPosition, StartPosition:Lerp(EndPosition, .5) + Vector3.new(0, (EndPosition - StartPosition).Magnitude / 2 + 1, 0), EndPosition, I)
		task.wait()
	end
	
	--// Create Particle
	GoreModule.CreateBloodSplatter(EndPosition)
	MethodsModule.DelayAction(.5, function() Part:Destroy() end)
	
	return Part	
end

function GoreModule.CreateBloodSplatter(SpawnPosition: Vector3)
	local StartSizeRatio = math.random(3, 6) / 10; local StartSize = Vector3.new(StartSizeRatio, 1.25, StartSizeRatio)
	local ExpandedSizeRatio = math.random(13, 19) / 10; local ExpandedSize = Vector3.new(ExpandedSizeRatio, .25, ExpandedSizeRatio)
	local LifeTime = math.random(4, 7)
	
	local BloodPart = MethodsModule.GetAsset("BloodPart"):Clone(); BloodPart.Parent = GoreCacheFolder
	BloodPart.Size = StartSize; BloodPart.Position = SpawnPosition

	MethodsModule.RepeatActionPereodically(0, 100, math.random(10, 22) / 10, function(StepValue)
		BloodPart.Size = BloodPart.Size:Lerp(ExpandedSize, StepValue / 100)
	end)
	
	MethodsModule.DelayAction(LifeTime, function()
		MethodsModule.RepeatActionPereodically(0, 100, math.random(10, 22) / 10, function(StepValue)
			BloodPart.Size = BloodPart.Size:Lerp(Vector3.new(0, 0, 0), StepValue / 100)
		end, function() BloodPart:Destroy() end)
	end)
	
	return BloodPart
end

function GoreModule.ApplyBleeding(Character: Model, WoundedPart: Part, SplattersAmount: number)
	if game:GetService("RunService"):IsServer() then
		RemoteCommunicator.FireAllClients("ApplyBleeding", {Character, WoundedPart, SplattersAmount})
		return	
	end
	
	local BloodParticles = MethodsModule.GetAsset("BloodParticles")
	for _, ParticleEmitter in pairs(BloodParticles:GetChildren()) do MethodsModule.SpawnParticles(ParticleEmitter, WoundedPart, math.random(20, 30)) end
	
	for I = 1, SplattersAmount do
		local DropPosition = GetDropPosition(Character, WoundedPart.Position + Vector3.new(math.random(-5, 5), 0, math.random(-5, 5)), Vector3.new(0, -50, 0), nil)
		if DropPosition then GoreModule.CreateBloodTrail(WoundedPart.Position, DropPosition) end
	end
end

return GoreModule