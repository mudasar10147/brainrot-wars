local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local camera = workspace.CurrentCamera
local player = Players.LocalPlayer

local playerGui = player:WaitForChild("PlayerGui")
local hud = playerGui:WaitForChild("HUD")
local container = hud:WaitForChild("Container")
local currencyContainer = container:WaitForChild("CurrencyContainer")

local goldAmount = currencyContainer:WaitForChild("Gold"):WaitForChild("GoldAmount")
local diamondAmount = currencyContainer:WaitForChild("Diamond"):WaitForChild("DiamondAmount")

local gui = playerGui:WaitForChild("TestGUI")
local iconTemplate = gui:WaitForChild("CoinIconTemplate")
local diamondTemplate = gui:WaitForChild("DiamondIconTemplate")

local ValuableCollected = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ValuableCollected")

local function FlyCoin(worldPos, valuableType)
	
	local icon
	
	if valuableType == "Diamond" then
		icon = diamondTemplate:Clone()
	else
		icon = iconTemplate:Clone()
	end
	
	icon.Visible = true
	icon.Parent = gui
	icon.AnchorPoint = Vector2.new(0.5,0.5)

	-- Initial size
	icon.Size = UDim2.new(0,80,0,80)

	-- Convert world → screen
	local screenPos = camera:WorldToViewportPoint(worldPos)
	icon.Position = UDim2.new(0,screenPos.X,0,screenPos.Y)

	-- Determine target UI
	local targetGui
	if valuableType == "Diamond" then
		targetGui = diamondAmount
	else
		targetGui = goldAmount
	end

	local targetPos = targetGui.AbsolutePosition + (targetGui.AbsoluteSize/2)

	-- POP animation (smooth overshoot)
	local popTween = TweenService:Create(
		icon,
		TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Size = UDim2.new(0,95,0,95)}
	)

	-- settle back
	local settleTween = TweenService:Create(
		icon,
		TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{Size = UDim2.new(0,80,0,80)}
	)

	-- slight upward float (professional feel)
	local floatTween = TweenService:Create(
		icon,
		TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{Position = icon.Position - UDim2.new(0,0,0,20)}
	)

	-- fly to currency UI
	local flyTween = TweenService:Create(
		icon,
		TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
		{
			Position = UDim2.new(0,targetPos.X,0,targetPos.Y),
			Size = UDim2.new(0,30,0,30)
		}
	)

	-- Chain animations smoothly
	popTween:Play()

	popTween.Completed:Connect(function()
		settleTween:Play()
	end)

	settleTween.Completed:Connect(function()
		floatTween:Play()
	end)

	floatTween.Completed:Connect(function()
		flyTween:Play()
	end)

	flyTween.Completed:Connect(function()
		icon:Destroy()
	end)

end

ValuableCollected.OnClientEvent:Connect(FlyCoin)