--// Services

local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--// References

local GameParts = ReplicatedStorage.GameSetup.GameParts

local GameUI = GameParts.UI

local Modules = ReplicatedStorage.Modules

local GeneralLibraries = Modules.GeneralLibraries
local MethodsModule = require(GeneralLibraries.MethodsModule)

local LuaExtensions = Modules.LuaExtensions
local QueueClass = require(LuaExtensions.Queue)

local Promise = require(ReplicatedStorage.Packages.Promise)

local Player = Players.LocalPlayer
local PlayerGui: PlayerGui = Player:WaitForChild("PlayerGui")

local Camera = workspace.CurrentCamera

--// Variables

local OpenGuis = {}
local NotificationsQueue = QueueClass.New()
local OptionalPromptsQueue = QueueClass.New()

--// Module

local GuiModule = {}

function GuiModule.GetNumberRounded(Number: number, Places: number)
	Places = math.pow(10, Places or 0)
	Number = Number * Places

	Number = Number >= 0 and math.floor(Number + 0.5) or math.ceil(Number - 0.5)

	return Number / Places
end

function GuiModule.GetNumberSorted(Number: number)
	local VALUES_TABLE = {
		{1 * math.pow(10, 3), "K+"},
		{1 * math.pow(10, 6), "M+"},
		{1 * math.pow(10, 9), "B+"},
		{1 * math.pow(10, 12), "T+"},
		{1 * math.pow(10, 15), "Qd+"},
		{1 * math.pow(10, 18), "Qn+"}
	}
	
	if Number <= 1000 then return tostring(GuiModule.GetNumberRounded(Number, 2)) end

	local String = ""

	for _, Value in pairs(VALUES_TABLE) do
		if Value[1] > Number then continue end
		String = GuiModule.GetNumberRounded(Number, 2)
	end

	return String
end

function GuiModule.PopUp(Object: any, ObjectToOpen: any)
	if Object:GetAttribute("IsBeingTweened") then return false end
	Object:SetAttribute("IsBeingTweened", true)

	local StartSize = Object.Size
	Object.Size = UDim2.new(0, 0, 0, 0)

	if ObjectToOpen then
		if ObjectToOpen:IsA("ScreenGui") or ObjectToOpen:IsA("BillboardGui") then ObjectToOpen.Enabled = true
		else ObjectToOpen.Visible = true end
	end

	local PopUpTween = MethodsModule.Tween(Object, {Size = StartSize}, TweenInfo.new(.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out))
	PopUpTween.Completed:Connect(function() Object:SetAttribute("IsBeingTweened", nil) end)
	PopUpTween:Play()

	return PopUpTween
end

function GuiModule.PopClose(Object: any, ObjectToClose: any)
	if Object:GetAttribute("IsBeingTweened") then return false end
	Object:SetAttribute("IsBeingTweened", true)

	local StartSize = Object.Size
	local SizeToSet = UDim2.new(0, 0, 0, 0)

	local PopCloseTween = MethodsModule.Tween(Object, {Size = SizeToSet}, TweenInfo.new(.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out))
	PopCloseTween.Completed:Connect(function()
		if ObjectToClose then
			if ObjectToClose:IsA("ScreenGui") or ObjectToClose:IsA("BillboardGui") then ObjectToClose.Enabled = false
			else ObjectToClose.Visible = false end
		end

		Object:SetAttribute("IsBeingTweened", nil)
		Object.Size = StartSize
	end)

	PopCloseTween:Play()

	return PopCloseTween
end

function GuiModule.FadeScreen(FadeTransparency: number, DisplayOrder: number, FadeDuration: number, Actions: {[a]: () -> nil})
	local FadeExisting = PlayerGui:FindFirstChild("Fade")
	if FadeExisting and FadeExisting.DisplayOrder == DisplayOrder and FadeExisting:GetAttribute("Duration") == nil then return end

	local FadeStartAction, FadeMiddleAction, FadeEndAction = table.unpack(Actions or {})

	local Fade = GameUI.Fade:Clone()
	Fade.Main.BackgroundTransparency = 1
	Fade.DisplayOrder = DisplayOrder
	Fade.Parent = PlayerGui
	Fade.Enabled = true

	if FadeStartAction then FadeStartAction() end

	local FadeStartTween: Tween = MethodsModule.Tween(Fade.Main, {BackgroundTransparency = FadeTransparency}, nil)
	local FadeEndTween: Tween = MethodsModule.Tween(Fade.Main, {BackgroundTransparency = 1}, nil)

	local function ClearFade()
		FadeEndTween.Completed:Connect(function()
			if FadeEndAction then FadeEndAction() end	
			Fade:Destroy()
		end)

		FadeEndTween:Play()
	end

	FadeStartTween.Completed:Connect(function()
		if FadeMiddleAction then FadeMiddleAction() end
		if FadeDuration then Fade:SetAttribute("Duration", FadeDuration); MethodsModule.DelayAction(FadeDuration, ClearFade) end
	end)

	FadeStartTween:Play()
	
	return ClearFade
end

function GuiModule.BlurScreen(BlurSize: number, BlurDuration: number, Actions: {[a]: () -> nil})
	local ExistingBlur = Camera:FindFirstChild("ModuleBlur") 
	if ExistingBlur and ExistingBlur.Size == BlurSize and ExistingBlur:GetAttribute("Duration") == nil then return end
	
	local BlurStartAction, BlurMiddleAction, BlurEndAction = table.unpack(Actions or {})
	
	local NewBlur = MethodsModule.Instantiate("BlurEffect", "ModuleBlur", nil, Camera, nil)
	NewBlur.Size = 0
	
	if BlurStartAction then BlurStartAction() end
	
	local BlurStartTween = MethodsModule.Tween(NewBlur, {Size = BlurSize}, nil)
	local BlurEndTween = MethodsModule.Tween(NewBlur, {Size = 0}, nil)

	local function ClearBlur()
		BlurEndTween.Completed:Connect(function()
			if BlurEndAction then BlurEndAction() end	
			NewBlur:Destroy()
		end)

		BlurEndTween:Play()
	end

	BlurStartTween.Completed:Connect(function()
		if BlurMiddleAction then BlurMiddleAction() end
		if BlurDuration then NewBlur:SetAttribute("Duration", BlurDuration); MethodsModule.DelayAction(BlurDuration, ClearBlur) end
	end)

	BlurStartTween:Play()

	return ClearBlur
end

function GuiModule.OpenGui(ObjectToTween: Frame, OpenObject: Frame | ScreenGui, BlurScreen: boolean, FadeScreen: boolean, OnOpenAction: () -> nil, OnCloseAction: () -> nil)
	if ObjectToTween:GetAttribute("BeingTweened") or OpenGuis[OpenObject] then return end
	ObjectToTween:SetAttribute("BeingTweened", true)
	
	local StartPosition = ObjectToTween.Position
	local PositionToSet = UDim2.new(StartPosition.X.Scale + 3, StartPosition.X.Offset, StartPosition.Y.Scale, StartPosition.Y.Offset)	
	
	ObjectToTween.Position = PositionToSet
	
	if OpenObject then
		if OpenObject:IsA("ScreenGui") then OpenObject.Enabled = true else OpenObject.Visible = true end
	end

	local OpenTween = MethodsModule.Tween(ObjectToTween, {Position = StartPosition}, nil)
	OpenTween.Completed:Connect(function()
		ObjectToTween:SetAttribute("BeingTweened", nil)
		if OnOpenAction then OnOpenAction() end
	end)
	
	OpenTween:Play()
	
	local RevertBlur: () -> nil = nil
	local RevertFade: () -> nil = nil
	
	if BlurScreen then RevertBlur = GuiModule.BlurScreen(14, nil, nil) end
	if FadeScreen then
		local DisplayOrder = OpenObject:IsA("ScreenGui") and OpenObject.DisplayOrder - 1 or OpenObject:FindFirstAncestorWhichIsA("ScreenGui", true).DisplayOrder - 1
		RevertFade = GuiModule.FadeScreen(.6, DisplayOrder, nil, nil)
	end
	
	local OpenGuiInfo = {
		ClearGui = function()
			if RevertBlur then RevertBlur() end
			if RevertFade then RevertFade() end
			
			GuiModule.CloseGui(ObjectToTween, OpenObject, OnCloseAction)
		end,
	}
	
	OpenGuis[OpenObject] = OpenGuiInfo
	
	return OpenGuiInfo
end

function GuiModule.CloseGui(ObjectToTween: Frame, OpenObject: Frame | ScreenGui, OnCloseAction: () -> nil)
	if ObjectToTween:GetAttribute("BeingTweened") then return end
	ObjectToTween:SetAttribute("BeingTweened", true)
	
	local StartPosition = ObjectToTween.Position
	local PositionToSet = UDim2.new(StartPosition.X.Scale + 3, StartPosition.X.Offset, StartPosition.Y.Scale, StartPosition.Y.Offset)	
	
	local CloseTween = MethodsModule.Tween(ObjectToTween, {Position = PositionToSet}, nil)
	CloseTween.Completed:Connect(function()
		if OpenObject then
			if OpenObject:IsA("ScreenGui") then OpenObject.Enabled = false else OpenObject.Visible = false end
		end
		
		ObjectToTween.Position = StartPosition
		ObjectToTween:SetAttribute("BeingTweened", nil)
		
		if OpenGuis[OpenObject] then OpenGuis[OpenObject] = nil end
		
		if OnCloseAction then OnCloseAction() end
	end)
	
	CloseTween:Play()
end

function GuiModule.CloseGuiByObject(OpenObject: Frame | ScreenGui)
	local OpenGuiInfo = OpenGuis[OpenObject]
	if OpenGuiInfo then OpenGuiInfo.ClearGui() end
end

function GuiModule.CreateTextNotification(Text: string, NotificationDuration: number)
	local TextNotifications: ScreenGui = PlayerGui:FindFirstChild("TextNotifications") or (function()
		local TextNotificationsGui = Instance.new("ScreenGui", PlayerGui)
		TextNotificationsGui.Name = "TextNotifications"
		local List = Instance.new("Frame", TextNotificationsGui)
		List.Name = "List"
		List.Size = UDim2.new(.3, 0, .2, 0)
		List.Position = UDim2.new(.5, 0, .02, 0)
		List.AnchorPoint = Vector2.new(.5, 0)
		List.BackgroundTransparency = 1
		List.BorderSizePixel = 0
		return TextNotificationsGui
	end)()
	
	local function CreateNotification()
		local NewNotification = GameUI.TextNotification:Clone()
		NewNotification.Text = Text
		
		local Transparency = NewNotification.TextTransparency
		NewNotification.TextTransparency = 1
		
		NewNotification.Parent = TextNotifications.List
		MethodsModule.Tween(NewNotification, {TextTransparency = Transparency}):Play()
		
		MethodsModule.DelayAction(NotificationDuration or 1, function()
			local DestroyTween = MethodsModule.Tween(NewNotification, {TextTransparency = 1})
			DestroyTween.Completed:Connect(function() NewNotification:Destroy() end)
			DestroyTween:Play()
		end)
	end
	
	local _, TextNotificationsAmount = MethodsModule.FindAllObjectsByRequirement(TextNotifications.List:GetChildren(), {
		{RequirementType = "Function", RequirementAction = function(Object) return Object.Name == "TextNotification" end}
	})
	
	NotificationsQueue:Enqueue({Action = CreateNotification})
	
	if NotificationsQueue.DequeueLaunched == true then return end
	NotificationsQueue.DequeueLaunched = true

	while #NotificationsQueue.Members > 0 do
		_, TextNotificationsAmount = MethodsModule.FindAllObjectsByRequirement(TextNotifications.List:GetChildren(), {
			{RequirementType = "Function", RequirementAction = function(Object) return Object.Name == "TextNotification" end}
		})
		
		if TextNotificationsAmount >= 3 then
			repeat
				_, TextNotificationsAmount = MethodsModule.FindAllObjectsByRequirement(TextNotifications.List:GetChildren(), {
					{RequirementType = "Function", RequirementAction = function(Object) return Object.Name == "TextNotification" end}
				})
				
				task.wait()
			until TextNotificationsAmount < 3
		end
		
		NotificationsQueue:Dequeue().Action()

		if #NotificationsQueue.Members <= 0 then NotificationsQueue.DequeueLaunched = false end
	end
end

function GuiModule.PutVFObject(ObjectModel: Model | MeshPart | Part, ViewportFrame: ViewportFrame)
	local Object, Camera = ViewportFrame:FindFirstChildWhichIsA("Model") or ViewportFrame:FindFirstChildWhichIsA("MeshPart"), ViewportFrame:FindFirstChildWhichIsA("Camera") or MethodsModule.Instantiate("Camera", nil, nil, ViewportFrame, nil)
	if Object then Object:Destroy() end

	local NewModel = ObjectModel:Clone()
	NewModel.Parent = ViewportFrame
	NewModel:SetAttribute("VF", true)
	
	local CFrameToSet: CFrame = nil

	if ObjectModel:IsA("Model") then
		local ExtentsSize = ObjectModel:GetExtentsSize()
		local MaxAxis = math.max(ExtentsSize.X, ExtentsSize.Y, ExtentsSize.Z)
		CFrameToSet = CFrame.new(ObjectModel.CameraPart.Position + ObjectModel.CameraPart.CFrame.LookVector * (MaxAxis * 1.3), ObjectModel.CameraPart.Position)
	else
		local ExtentsSize = ObjectModel.Size
		local MaxAxis = math.max(ExtentsSize.X, ExtentsSize.Y, ExtentsSize.Z)
		CFrameToSet = CFrame.new(ObjectModel.CameraPart.Position + ObjectModel.CameraPart.CFrame.RightVector * (MaxAxis * 1.3), ObjectModel.CameraPart.Position)
	end

	Camera.CFrame = CFrameToSet
	ViewportFrame.CurrentCamera = Camera
end

function GuiModule.ClearVF(ViewportFrame: ViewportFrame)
	local Model = ViewportFrame:FindFirstChildWhichIsA("Model") or ViewportFrame:FindFirstChildWhichIsA("MeshPart") or ViewportFrame:FindFirstChildWhichIsA("Part")
	if Model and Model:GetAttribute("VF") then Model:Destroy() end
end

function GuiModule.ForceOptionalPrompt(promptText: string, enableAgreeOption: boolean, enableCancelOption: boolean, addToQueue: boolean)
	local _, promptsAmount = MethodsModule.FindAllObjectsByRequirement(PlayerGui:GetDescendants(), {
		{RequirementType = "Function", RequirementAction = function(object: Instance) return object:GetAttribute("OptionalPrompt") == true end}
	})

	local newPromise = Promise.new(function(resolve: () -> nil)
		OptionalPromptsQueue:Enqueue({Action = function()
			local newPrompt = GameUI.OptionalPrompt:Clone()
			local promptInner = newPrompt.Main.Inner
			
			if(enableAgreeOption == false) then promptInner.Buttons.Agree.Visible = false end
			if(enableCancelOption == false) then promptInner.Buttons.Cancel.Visible = false end
	
			promptInner.TextLabel.Text = promptText
			
			promptInner.Buttons.Agree.MouseButton1Click:Connect(function() resolve(true); newPrompt:Destroy() end)
			promptInner.Buttons.Cancel.MouseButton1Click:Connect(function() resolve(false); newPrompt:Destroy() end)
			
			newPrompt.Parent = PlayerGui
			GuiModule.PopUp(newPrompt.Main, newPrompt)
		end})
	end)

	if(OptionalPromptsQueue.DequeueLaunched ~= true) then
		OptionalPromptsQueue.DequeueLaunched = true
		
		while(#OptionalPromptsQueue.Members > 0) do
			_, promptsAmount = MethodsModule.FindAllObjectsByRequirement(PlayerGui:GetDescendants(), {
				{RequirementType = "Function", RequirementAction = function(object: Instance) return object:GetAttribute("OptionalPrompt") == true end}
			})

			if(promptsAmount > 0) then
				repeat
					_, promptsAmount = MethodsModule.FindAllObjectsByRequirement(PlayerGui:GetDescendants(), {
						{RequirementType = "Function", RequirementAction = function(object: Instance) return object:GetAttribute("OptionalPrompt") == true end}
					})
					task.wait()
				until promptsAmount <= 0
			end

			OptionalPromptsQueue:Dequeue().Action()

			if(#OptionalPromptsQueue.Members <= 0) then OptionalPromptsQueue.DequeueLaunched = false end
		end
	end

	return newPromise
end

return GuiModule