--// Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

--// References

local Modules = ReplicatedStorage.Modules

local GeneralLibraries = Modules.GeneralLibraries
local MethodsModule = require(GeneralLibraries.MethodsModule)

--// Module

local DataModule = {}

function DataModule.SetAsync(DataStoreName: string, AsyncId: string, DataTable: {[a]: any})
	local DataStore = DataStoreService:GetDataStore(DataStoreName)
	if not DataStore then warn("No data store found!"); return end
	
	local Success, Result = MethodsModule.Try(function()
		DataStore:SetAsync(AsyncId, DataTable)	
	end, 5, 1, true)
	
	if not Success then warn(Result) end
end

function DataModule.GetAsync(DataStoreName: string, AsyncId: string)
	local DataStore = DataStoreService:GetDataStore(DataStoreName)
	if not DataStore then warn("No data store found!"); return end
	
	local Data: {[a]: any} = nil
	
	local Success, Result = MethodsModule.Try(function()
		Data = DataStore:GetAsync(AsyncId)
	end, 5, 1, true)
	
	if not Data or not Success then warn(Result); return end
	
	return Data
end

return DataModule