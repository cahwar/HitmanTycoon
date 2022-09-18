--// Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// References

local AnimationsFolder = ReplicatedStorage.GameSetup.GameParts.Animations

local Modules = ReplicatedStorage.Modules

local GeneralLibraries = Modules.GeneralLibraries
local MethodsModule = require(GeneralLibraries.MethodsModule)

--// Variables

local LoadedAnimations = {}
local Connections = {}

--// Functions

local function FindAnimationTrack(Model: Model, AnimationTrackName: string)
	local ModelAnimationTracks = LoadedAnimations[Model]
	if not ModelAnimationTracks then warn("Model does not have any animation track loaded"); return false end
	
	local AnimationTrack = ModelAnimationTracks[AnimationTrackName]
	if not AnimationTrack then warn("No animation track found with this name"); return false end
	
	return AnimationTrack
end

--// Module

local AnimationsModule = {}

function AnimationsModule.LoadAnimation(Model: Model, Animation: Animation)
	if typeof(Animation) ~= "string" and Animation:IsA(Animation) == false then return end
	
	if typeof(Animation) == "string" then
		Animation = AnimationsFolder:FindFirstChild(Animation, true)
		if not Animation then warn("Animation with this name does not exist in the game:", Animation); return false end
	end
	
	local AnimationTrackLoaded = FindAnimationTrack(Model, Animation.Name)
	if AnimationTrackLoaded then return AnimationTrackLoaded end
	
	if LoadedAnimations[Model] == nil then LoadedAnimations[Model] = {} end
	local AnimationTrack = Model:FindFirstChildWhichIsA("Humanoid"):LoadAnimation(Animation)
	
	LoadedAnimations[Model][Animation.Name] = AnimationTrack
	
	return AnimationTrack
end

function AnimationsModule.LoadAnimationsPack(Model: Model, Animations: {[a]: Animation})
	for _, Animation in pairs(Animations) do
		AnimationsModule.LoadAnimation(Model, Animation)
	end
end

function AnimationsModule.PlayAnimation(Model: Model, Animation: string | Animation, FadeTime: number, AnimationSpeed: number, EndAction: () -> nil, MarkersActions: {[a]: () -> nil})
	local AnimationTrack: AnimationTrack = AnimationsModule.LoadAnimation(Model, Animation)
	if AnimationTrack then
		if not Connections[AnimationTrack] then Connections[AnimationTrack] = {} end
		
		if MarkersActions and MethodsModule.GetTableLength(MarkersActions) > 0 then
			for MarkerName, Action in pairs(MarkersActions) do
				if Connections[AnimationTrack][MarkerName] ~= nil then continue end
				Connections[AnimationTrack][MarkerName] = AnimationTrack:GetMarkerReachedSignal(MarkerName):Connect(Action)
			end	
		end

		if EndAction and Connections[AnimationTrack].EndAction == nil then
			Connections[AnimationTrack].EndAction = AnimationTrack.Stopped:Connect(EndAction)
		end
		
		AnimationTrack:Play(FadeTime or 0)
		if AnimationSpeed and AnimationTrack.Speed ~= AnimationSpeed then AnimationTrack:AdjustSpeed(AnimationSpeed) end
	end
end

function AnimationsModule.StopAnimation(Model: Model, Animation: string | Animation, FadeTime: number)
	local AnimationTrack = FindAnimationTrack(Model, Animation)
	if not AnimationTrack or AnimationTrack.IsPlaying == false then return end
	
	AnimationTrack:Stop(FadeTime or 0)
end

return AnimationsModule