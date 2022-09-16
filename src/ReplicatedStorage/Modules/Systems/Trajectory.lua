--// Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// References

local Modules = ReplicatedStorage.Modules

local GeneralLibraries = Modules.GeneralLibraries
local MethodsModule = require(GeneralLibraries.MethodsModule)

--// Functions

local function CreateTrajectoryPart(Name: string, Point: Vector3)
	local TrajectoryPart = MethodsModule.Instantiate("Part", Name, nil, workspace, nil)
	TrajectoryPart.Position = Point
	TrajectoryPart.Transparency = 1
	TrajectoryPart.Anchored = true
	TrajectoryPart.CanCollide = false
	
	local Attachment0 = MethodsModule.Instantiate("Attachment", "Attachment", nil, TrajectoryPart)
	
	local Beam:Beam = MethodsModule.Instantiate("Beam", "Beam", nil, TrajectoryPart, nil)
	Beam.Attachment0 = Attachment0
	Beam.FaceCamera = true
	
	return TrajectoryPart
end

--// Module

TrajectoryLine = {}

function TrajectoryLine.DrawTrajectoryLine(StartPoint: Vector3, MiddlePoint: Vector3, EndPoint: Vector3)
	local TrajectoryStartPart = CreateTrajectoryPart("TrajectoryStart", StartPoint); local StartConnection: Part = nil
	local TrajectoryEndPart = CreateTrajectoryPart("TrajectoryEnd", EndPoint); local EndConnection: Part = nil
	
	local TemporaryPart: Part = nil
	
	local TrajectoryPartsTable = {}
	MethodsModule.InsertMultiple(TrajectoryPartsTable, TrajectoryStartPart, TrajectoryEndPart)
	
	for I = 0, 1, .01 do
		local Bezier = MethodsModule.GetBezier(StartPoint, MiddlePoint, EndPoint, I)
		local TrajectoryPart = CreateTrajectoryPart("Trajectory"..tostring(I), Bezier)
		
		if MethodsModule.Approximately(I, 1, .01) and EndConnection == nil then TrajectoryEndPart.Beam.Attachment1 = TrajectoryPart.Attachment; EndConnection = TrajectoryPart
		elseif MethodsModule.Approximately(I, 0, .01) and StartConnection == nil then TrajectoryStartPart.Beam.Attachment1 = TrajectoryPart.Attachment; StartConnection = TrajectoryPart end

		if TemporaryPart then
			TemporaryPart.Beam.Attachment1 = TrajectoryPart.Attachment
		end
		
		TemporaryPart = TrajectoryPart
		
		table.insert(TrajectoryPartsTable, TrajectoryPart)
	end
	
	return TrajectoryPartsTable
end

return TrajectoryLine