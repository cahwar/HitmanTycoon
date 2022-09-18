--// Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Reference

local Modules = ReplicatedStorage.Modules

local GeneralLibraries = Modules.GeneralLibraries
local MethodsModule = require(GeneralLibraries.MethodsModule)

--// Module

local QueueClass = {}
QueueClass.__index = QueueClass

function QueueClass.New()
	local NewQueue = setmetatable({}, QueueClass)
	NewQueue.Members = {}
	return NewQueue
end

function QueueClass:Enqueue(...)
	local Objects = {...}
	for _, Object in pairs(Objects) do	
		Object = typeof(Object) == "table" and Object or {Object = Object}
		table.insert(self.Members, Object)
	end
end

function QueueClass:Dequeue(Action)
	local ObjectsAmount = MethodsModule.GetTableLength(self.Members)
	if ObjectsAmount <= 0 then
		warn("No objects left in queue")
		return false
	end
	
	local FirstObject = self.Members[1]
	self.Members[1] = nil
	
	for Index, Object in pairs(self.Members) do
		self.Members[Index - 1] = Object
	end
	
	self.Members[MethodsModule.GetTableLength(self.Members)] = nil
	
	if Action then Action() end
	
	return FirstObject
end

function QueueClass:FindMember(MemberName: string)
	for _, QueueMember in pairs(self.Members) do
		if QueueMember.Name == MemberName then return QueueMember end
	end

	return false
end

return QueueClass