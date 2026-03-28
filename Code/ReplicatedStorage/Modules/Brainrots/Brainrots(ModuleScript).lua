local Brainrots = {
	-- COMMONS
	BananaDancana = {
		Id = "BananaDancana",
		Name = "Banana Dancana",
		Model = "Banana Dancana",
		Icon = "rbxassetid://94818796677848",
		Tier = "Common",
		IsStarter = true
	},
	PandacciniBananini = {
		Id = "PandacciniBananini",
		Name = "Pandaccini Bananini",
		Model = "Pandaccini Bananini",
		Icon = "rbxassetid://94818796677848",
		Tier = "Common",
		IsStarter = true
	},
	NyanniniCattalini = {
		Id = "NyanniniCattalini",
		Name = "Nyannini Cattalini",
		Model = "Nyannini Cattalini",
		Icon = "rbxassetid://94818796677848",
		Tier = "Common",
		IsStarter = true
	},
	PipiPotato = {
		Id = "PipiPotato",
		Name = "Pipi Potato",
		Model = "Pipi Potato",
		Icon = "rbxassetid://94818796677848",
		Tier = "Common",
		IsStarter = true
	},
	TimCheese = {
		Id = "TimCheese",
		Name = "Tim Cheese",
		Model = "Tim Cheese",
		Icon = "rbxassetid://94818796677848",
		Tier = "Common",
		IsStarter = true
	},
	ChillinChili = {
		Id = "ChillinChili",
		Name = "Chillin Chili",
		Model = "Chillin Chili",
		Icon = "rbxassetid://94818796677848",
		Tier = "Common",
		IsStarter = true
	},
	-- UNCOMMONS
	BananacciniSupremo = {
		Id = "BananacciniSupremo",
		Name = "Bananaccini Supremo",
		Model = "Bananaccini Supremo",
		Icon = "rbxassetid://94818796677848",
		Tier = "Uncommon",
		IsStarter = false
	},
	BananaNyaneroni = {
		Id = "BananaNyaneroni",
		Name = "Banana Nyaneroni",
		Model = "Banana Nyaneroni",
		Icon = "rbxassetid://94818796677848",
		Tier = "Uncommon",
		IsStarter = false
	},
	BananitoPotatino = {
		Id = "BananitoPotatino",
		Name = "Bananito Potatino",
		Model = "Bananito Potatino",
		Icon = "rbxassetid://94818796677848",
		Tier = "Uncommon",
		IsStarter = false
	},
	PandacciniFormaggi = {
		Id = "PandacciniFormaggi",
		Name = "Pandaccini Formaggi",
		Model = "Pandaccini Formaggi",
		Icon = "rbxassetid://94818796677848",
		Tier = "Uncommon",
		IsStarter = false
	},
	CattaliniChilini = {
		Id = "CattaliniChilini",
		Name = "Cattalini Chilini",
		Model = "Cattalini Chilini",
		Icon = "rbxassetid://94818796677848",
		Tier = "Uncommon",
		IsStarter = false
	},
	ChillinFormaggino = {
		Id = "ChillinFormaggino",
		Name = "Chillin Formaggino",
		Model = "Chillin Formaggino",
		Icon = "rbxassetid://94818796677848",
		Tier = "Uncommon",
		IsStarter = false
	},
}

-- Map spawn/model display strings (e.g. "Banana Dancana") to inventory key (e.g. "BananaDancana").
function Brainrots.ResolveInventoryId(candidate)
	if type(candidate) ~= "string" or candidate == "" then
		return nil
	end
	local direct = Brainrots[candidate]
	if type(direct) == "table" and direct.Id then
		return direct.Id
	end
	for _, data in pairs(Brainrots) do
		if type(data) == "table" and data.Id then
			if data.Id == candidate or data.Name == candidate or data.Model == candidate then
				return data.Id
			end
		end
	end
	return nil
end

return Brainrots