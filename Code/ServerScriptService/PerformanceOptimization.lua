local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Optimize workspace
local function optimizeWorkspace()
	local Workspace = game:GetService("Workspace")
	
	-- Set streaming mode for better performance
	Workspace.StreamingEnabled = true
	Workspace.StreamingMinRadius = 64
	Workspace.StreamingTargetRadius = 1024
	
	-- Optimize physics
	Workspace.PhysicsSteppingMethod = Enum.PhysicsSteppingMethod.Fixed
	
	return "Workspace optimized"
end

-- Optimize lighting
local function optimizeLighting()
	local Lighting = game:GetService("Lighting")
	
	-- Disable expensive effects
	Lighting.GlobalShadows = false
	Lighting.ShadowSoftness = 0
	Lighting.GeographicLatitude = 41.7
	
	-- Set reasonable lighting values
	Lighting.ClockTime = 14
	Lighting.Brightness = 2
	Lighting.ExposureCompensation = 0
	
	return "Lighting optimized"
end

-- Optimize network
local function optimizeNetwork()
	-- Set network owner for parts to reduce replication
	local Workspace = game:GetService("Workspace")
	
	for _, part in Workspace:GetDescendants() do
		if part:IsA("BasePart") and part.Anchored then
			-- Set network owner to nil for anchored parts
			pcall(function()
				part:SetNetworkOwner(nil)
			end)
		end
	end
	
	return "Network optimized"
end

-- Run optimizations
local function runOptimizations()
	local results = {}
	
	table.insert(results, optimizeWorkspace())
	table.insert(results, optimizeLighting())
	table.insert(results, optimizeNetwork())
	
	print("[ServerPerformanceOptimization] Optimizations complete:")
	for _, result in results do
		print("  - " .. result)
	end
	
	return results
end

-- Run optimizations when server starts
runOptimizations()

-- Monitor server performance
RunService.Heartbeat:Connect(function()
	-- Monitor server performance
	local stats = game:GetService("Stats")
	
	-- If server is under heavy load, log it
	if stats:GetTotalMemoryUsageMb() > 1000 then
		warn("[ServerPerformanceOptimization] High memory usage: " .. stats:GetTotalMemoryUsageMb() .. " MB")
	end
end)

print("[ServerPerformanceOptimization] Script loaded successfully")