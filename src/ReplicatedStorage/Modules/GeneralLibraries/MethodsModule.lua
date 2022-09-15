--// Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

--// References

local GameParts = ReplicatedStorage.GameParts

--// Module

local MethodsModule = {}

function MethodsModule.Instantiate(ObjectType: string, ObjectName: string, ObjectValue: any, ObjectParent: any, ObjectAttributes: {[a]: any})
	local NewObject = Instance.new(ObjectType, ObjectParent)
	
	if ObjectName then NewObject.Name = ObjectName end
	if ObjectValue then NewObject.Value = ObjectValue end
	
	if ObjectAttributes then
		for AttributeName, AttributeValue in pairs(ObjectAttributes) do NewObject:SetAttribute(AttributeName, AttributeValue) end
	end
	
	return NewObject
end

function MethodsModule.GetTableLength(Table): number
	local TableLength: number = 0
	for _, _ in Table do TableLength += 1 end
	return TableLength
end

function MethodsModule.GetSourceType(): string
	return RunService:IsClient() and "Client" or "Server"
end

function MethodsModule.Try(Action: () -> nil, AttemptsAmount: number, AttemptsCooldown: number, Debug: boolean?): boolean
	AttemptsCooldown = AttemptsCooldown or .5

	local Success: boolean, Result: string, CurrentAttemptsAmount = nil, nil, 0

	repeat
		Success, Result = pcall(Action)
		if not Success or Result == false then
			CurrentAttemptsAmount += 1
			if Debug ~= false then warn(Result, ".\n", "Retrying, attempts:", CurrentAttemptsAmount) end

			task.wait(AttemptsCooldown)
		end
	until (Success == true and Result ~= false) or CurrentAttemptsAmount >= AttemptsAmount

	return Success, Result
end

function MethodsModule.ClearConnections(Connections: {[a]: RBXScriptConnection | {[a]: RBXScriptConnection}})
	for Index, Value in pairs(Connections) do
		if typeof(Value) == "table" then
			MethodsModule.ClearConnections(Value)
		else
			Value:Disconnect()
		end
		
		Connections[Index] = nil
	end
end

function MethodsModule.Disconnect(Connections: {[a]: RBXScriptConnection}, ConnectionName: string)
	local Connection = Connections[ConnectionName]
	if Connection then Connection:Disconnect() end
end

function MethodsModule.RepeatActionPereodically(StartNumber: number, PointNumber: number, Duration: number, StepFunction: (number) -> number, EndAction: () -> nil)
	if MethodsModule.Approximately(StartNumber, PointNumber, .5) then
		if EndAction then EndAction() end; return
	end
	
	local Step = (PointNumber - StartNumber) / (Duration * 60)
	local Stopped = false
	
	task.spawn(function()
		for i = StartNumber, PointNumber, Step do
			if Stopped == true then return end
			
			StepFunction(i)
			task.wait()
		end

		StepFunction(PointNumber)

		if EndAction then EndAction() end
	end)
	
	local function StopFunction()
		Stopped = true
	end
	
	return StopFunction
end

function MethodsModule.LerpNumber(Number: number, PointNumber: number, LerpRatio: number)
	return Number + ((PointNumber - Number) * LerpRatio)
end

export type Requirement = {RequirementType: string, RequirementAction: (Instance) -> boolean, RequirementName: string, RequirementValue: any}
function MethodsModule.FindObjectByRequirement(Table, Requirements: { [a]: Requirement })
	for _, RequirementInfo in pairs(Requirements) do
		for _, Object: Instance in pairs(table) do
			local CheckSuccess: boolean, Result: boolean = nil
			
			if RequirementInfo.RequirementType == "Attribute" then CheckSuccess, Result = pcall(function() return Object:GetAttribute(RequirementInfo.RequirementName) == RequirementInfo.RequirementValue end)
			elseif RequirementInfo.RequirementType == "Property" then CheckSuccess, Result = pcall(function() return Object[RequirementInfo.RequirementName] == RequirementInfo.RequirementValue end)
			elseif RequirementInfo.RequirementType == "Function" then CheckSuccess, Result = pcall(function() return RequirementInfo.RequirementAction(Object) end) end

			if Result == false or CheckSuccess == false then
				if CheckSuccess == false then print(Result) end
				continue	
			end
			
			return Object
		end
	end
	
	warn("No object found")
	return false
	--for _, Object: Instance in pairs(Table) do
	--	local Result: boolean, CheckSuccess: boolean = nil, nil
		
	--	for _, RequirementInfo: Requirement in pairs(Requirements) do
	--		local CheckSuccess: boolean = nil
			
	--		if RequirementInfo.RequirementType == "Attribute" then CheckSuccess, Result = pcall(function() return Object:GetAttribute(RequirementInfo.RequirementName) == RequirementInfo.RequirementValue end)
	--		elseif RequirementInfo.RequirementType == "Property" then CheckSuccess, Result = pcall(function() return Object[RequirementInfo.RequirementName] == RequirementInfo.RequirementValue end)
	--		elseif RequirementInfo.RequirementType == "Function" then CheckSuccess, Result = pcall(function() return RequirementInfo.RequirementAction(Object) end) end
			
	--		if Result == false or CheckSuccess == false then
	--			if CheckSuccess == false then print(Result) end
				
	--		end
	--	end
		
	--	if Result == true then return Object end
	--end
	
	--warn("No object found!")
end

function MethodsModule.FindAllObjectsByRequirement(Table, Requirements: { [a]: Requirement })
	local ObjectsFound = {}
	
	for _, Object: Instance in pairs(Table) do
		local Result: boolean = nil

		for _, RequirementInfo: Requirement in pairs(Requirements) do
			local CheckSuccess: boolean = nil

			if RequirementInfo.RequirementType == "Attribute" then CheckSuccess, Result = pcall(function() return Object:GetAttribute(RequirementInfo.RequirementName) == RequirementInfo.RequirementValue end)
			elseif RequirementInfo.RequirementType == "Property" then CheckSuccess, Result = pcall(function() return Object[RequirementInfo.RequirementName] == RequirementInfo.RequirementValue end)
			elseif RequirementInfo.RequirementType == "Function" then CheckSuccess, Result = pcall(function() return RequirementInfo.RequirementAction(Object) end) end

			if Result == false or CheckSuccess == false then
				if CheckSuccess == false then print(Result) end
				continue
			end
		end

		if Result == true then table.insert(ObjectsFound, Object) end
	end
	
	return ObjectsFound, #ObjectsFound
end

function MethodsModule.RealizeBreakConnections(ReferenceConnections, BreakConnections, BreakAction)
	if not BreakConnections or MethodsModule.GetTableLength(BreakConnections) <= 0 then return end

	for Object, Event in pairs(BreakConnections) do
		ReferenceConnections[#ReferenceConnections + 1] = Object[Event]:Connect(function()
			if BreakAction then BreakAction() end
			warn("Break Connection")
		end)
	end
end

function MethodsModule.DelayAction(Time: number, Action, BreakConnections)
	local StartTime = tick()
	local DelayConnections = {}

	local function ClearDelay()
		warn("Clear Delay")
		MethodsModule.ClearConnections(DelayConnections)
	end

	MethodsModule.RealizeBreakConnections(DelayConnections, BreakConnections, ClearDelay)

	DelayConnections[#DelayConnections + 1] = RunService.Heartbeat:Connect(function()
		if tick() - StartTime >= Time then
			MethodsModule.ClearConnections(DelayConnections)
			Action()
		end
	end)
	
	return ClearDelay
end

function MethodsModule.Approximately(Value1, Value2, Radius: number)
	Radius = Radius or 4

	if typeof(Value1) ~= "number" then
		Value1 = math.abs(Value1.X) + math.abs(Value1.Y) + math.abs(Value1.Z)
		Value2 = math.abs(Value2.X) + math.abs(Value2.Y) + math.abs(Value2.Z)
	end

	local Difference = Value2 - Value1

	return math.abs(Difference) <= Radius, Difference
end

function MethodsModule.Switch(ComparingObject: any, SwitchStatements: {[a]: any}, Default: any?)
	for	_, StatementInfo in pairs(SwitchStatements) do
		if ComparingObject == StatementInfo.Value then
			if StatementInfo.Action then StatementInfo.Action() end
			return StatementInfo.Value
		end
	end

	if Default then
		if Default.Action then Default.Action() end
		return Default
	end

	return nil
end

function MethodsModule.Tween(Object: any, PointTable: {[a]: any}, EasingInfo: TweenInfo)
	EasingInfo = EasingInfo or TweenInfo.new(.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	local Tween = TweenService:Create(Object, EasingInfo, PointTable)
	return Tween
end

function MethodsModule.Raycast(OriginPosition, Direction, RaycastParamsInfo)
	if not RaycastParamsInfo then
		RaycastParamsInfo = RaycastParams.new()
		RaycastParamsInfo.IgnoreWater = true
	end
	
	local RaycastResult: RaycastResult = workspace:Raycast(OriginPosition, Direction, RaycastParamsInfo)
	
	return RaycastResult
end

function MethodsModule.GetBezier(StartPoint: Vector3, MiddlePoint: Vector3, EndPoint: Vector3, Ratio: number)
	local StartMiddle = StartPoint:Lerp(MiddlePoint, Ratio)
	local MiddleEnd = MiddlePoint:Lerp(EndPoint, Ratio)
	local StartMiddleEnd = StartMiddle:Lerp(MiddleEnd, Ratio)
	return StartMiddleEnd
end

function MethodsModule.InsertMultiple(Table, InsertNamingType: string, ...)
	for _, Object in pairs({...}) do
		if InsertNamingType == "Name" then Table[Object.Name] = Object
		else table.insert(Table, Object) end
	end
end

function MethodsModule.WeldObjects(Object0, Object1)
	local Weld = Instance.new("Weld")
	Weld.Part0 = Object0
	Weld.Part1 = Object1
	Weld.Parent = Weld.Part0

	return Weld
end

function MethodsModule.GetAsset(AssetName: string)
	return GameParts:FindFirstChild(AssetName, true)
end

function MethodsModule.SpawnParticles(Particles: ParticleEmitter | string, ParticlesPart: Part, AmountToEmit: number)
	local Particles = Particles:IsA("ParticleEmitter") and Particles or MethodsModule.GetAsset(Particles)
	if not Particles then warn("No particles found!"); return end
	
	local NewParticles = Particles:Clone()
	NewParticles.Parent = ParticlesPart
	NewParticles:Emit(AmountToEmit)
	
	MethodsModule.DelayAction(2 + AmountToEmit / 60, function() NewParticles:Destroy() end)
end

function MethodsModule.GetWithChance(ObjectsChancesTable: {[a]: any?})
	local ChanceRatio = (function() local OverallChance: number = 0; for _, Chance in pairs(ObjectsChancesTable) do OverallChance += Chance end; return OverallChance end)()
	local RandomChance = math.random(1, ChanceRatio)
	local Weight = 0
	
	table.sort(ObjectsChancesTable, function(Chance1, Chance2) return Chance1 < Chance2 end)
	
	for Object, Chance in pairs(ObjectsChancesTable) do
		Weight += Chance; if Weight >= RandomChance then return Object end
	end
	
	warn("Error!")
end

return MethodsModule