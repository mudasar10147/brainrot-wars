local ValuablesService = {}

function ValuablesService.DestroyCoin(Valuable)
	Valuable:Destroy()
	print("Valuable Detected")
end

function ValuablesService.SpawnCoin(position)

	local Valuable = game.ServerStorage.Coin:Clone()
	Valuable.Position = position
	Valuable.Parent = workspace.Coins

end

return ValuablesService