local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- Wait for game to load
task.wait(2)

-- Optimize graphics settings
local function optimizeGraphics()
	-- Set quality level to balanced (better performance)
	local UserGameSettings = UserSettings():GetService("UserGameSettings")
	UserGameSettings.SavedQualityLevel = Enum.SavedQualityLevel.QualityLevel2
	
	-- Disable unnecessary effects
	local Lighting = game:GetService("Lighting")
	Lighting.GlobalShadows = false
	Lighting.Brightness = 2
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1
	Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
	
	return "Graphics optimized"
end

-- Optimize physics
local function optimizePhysics()
	-- Reduce physics quality for better performance
	local PhysicsService = game:GetService("PhysicsService")
	
	-- Set physics quality to medium
	game.PhysicsSettings.PhysicsEnvironmentalThrottle = Enum.PhysicsEnvironmentalThrottle.Default
	
	return "Physics optimized"
end

-- Optimize UI
local function optimizeUI()
	-- Reduce UI update frequency
	local playerGui = player:WaitForChild("PlayerGui")
	
	-- Optimize all UI elements
	for _, gui in playerGui:GetDescendants() do
		if gui:IsA("GuiObject") then
			-- Enable clipping only when necessary
			if gui:IsA("Frame") or gui:IsA("ScrollingFrame") then
				gui.ClipsDescendants = true
			end
		end
	end
	
	return "UI optimized"
end

-- Run optimizations
local function runOptimizations()
	local results = {}
	
	table.insert(results, optimizeGraphics())
	table.insert(results, optimizePhysics())
	table.insert(results, optimizeUI())
	
	print("[PerformanceOptimization] Optimizations complete:")
	for _, result in results do
		print("  - " .. result)
	end
	
	return results
end

-- Run optimizations when player joins
runOptimizations()

-- Monitor performance and adjust if needed
RunService.Heartbeat:Connect(function()
	-- Get current FPS
	local fps = 1 / RunService.Heartbeat:Wait()
	
	-- If FPS drops below 30, further optimize
	if fps < 30 then
		-- Reduce quality level
		local UserGameSettings = UserSettings():GetService("UserGameSettings")
		if UserGameSettings.SavedQualityLevel ~= Enum.SavedQualityLevel.QualityLevel1 then
			UserGameSettings.SavedQualityLevel = Enum.SavedQualityLevel.QualityLevel1
			print("[PerformanceOptimization] Reduced quality level due to low FPS")
		end
	end
end)

print("[PerformanceOptimization] Script loaded successfully")