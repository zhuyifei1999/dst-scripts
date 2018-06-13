local USE_SETTINGS_FILE = PLATFORM ~= "PS4" and PLATFORM ~= "NACL"

local MAX_RECIPES = 3

local QuagmireRecipeBook = Class(function(self)
	self.recipes = {}
    self.dirty = false
	self.filters = {}
end)

function QuagmireRecipeBook:IsRecipeUnlocked(product)
	local split_name = string.split(product, "_")
	local achievement_name = "food_"..split_name[#split_name]
	return EventAchievements:IsAchievementUnlocked(FESTIVAL_EVENTS.QUAGMIRE, achievement_name)
end

function QuagmireRecipeBook:GetValidRecipes()
	local sessionid = TheNet:GetSessionIdentifier()
	local ret = {}
	for k, v in pairs(self.recipes) do
		local split_name = string.split(k, "_")
		local achievement_name = "food_"..split_name[#split_name]
		local achievement_unlocked = EventAchievements:IsAchievementUnlocked(FESTIVAL_EVENTS.QUAGMIRE, achievement_name)

		local temp_unlocked = sessionid ~= nil and v.session == sessionid

		if achievement_unlocked or temp_unlocked then
			ret[k] = v
		end
	end

	return ret
end

function QuagmireRecipeBook:Load()
	self.recipes = {}
	TheSim:GetPersistentString("recipebook", function(load_success, data) 
		if load_success and data ~= nil then
			local status, recipe_book = pcall( function() return json.decode(data) end )
		    if status and recipe_book then
				self.recipes = recipe_book
			else
				print("Faild to load the recipe book!")
			end

			self.dirty = false
		end
	end)
end

function QuagmireRecipeBook:Save()
	if not self.dirty then
		return
	end

	if TheWorld ~= nil then
		TheWorld:PushEvent("quagmire_refreshrecipbookwidget")
	end

	local str = json.encode(self.recipes)
	TheSim:SetPersistentString("recipebook", str, false, function() 
		self.dirty = false 
		print("Done writing recipe book.")
	end)
end

local function RemoveCookedFromName(ingredients)
	local ret = {}
		for i, v in ipairs(ingredients) do
			local str = v
			str = string.gsub(str, "_cooked_", "")
			str = string.gsub(str, "cooked_", "")
			str = string.gsub(str, "quagmire_cooked", "quagmire_")
			str = string.gsub(str, "_cooked", "")
			str = string.gsub(str, "cooked", "")
			table.insert(ret, str)
		end
	return ret
end

local function IsKnownIngredients(recipes, ingredients)
	for ri, known_recipe in ipairs(recipes) do
		local known = true
		for i, ingredient in ipairs(ingredients) do
			if ingredients[i] ~= known_recipe[i] then
				known = false
				break
			end
		end
		if known then
			return ri
		end
	end
end

local function OnRecipeDiscovered(self, data)
	local new_recipe = false

	if string.sub(data.product, -5) ~= "burnt" and string.sub(data.product, -4) ~= "goop" then
		local ingredients = RemoveCookedFromName(data.ingredients)
		table.sort(ingredients)

		local station_size = data.dish ~= nil and (#ingredients == 3 and "small" or "large") or "syrup"

		if self.recipes[data.product] == nil then
			self.recipes[data.product] = 
			{
				dish = data.dish,
				station = {data.station},
				size = station_size,
				new = "new",
				date = os.date("%d/%m/%Y/%X"),
				recipes = {ingredients},
				session = TheNet:GetSessionIdentifier(),
			}
			self.dirty = true
			new_recipe = true
		else
			local recipe = self.recipes[data.product]

			local sessionid = TheNet:GetSessionIdentifier()

			if recipe.session ~= sessionid and not self:IsRecipeUnlocked(data.product) then
				new_recipe = true
			end

			recipe.session = sessionid

			if recipe.size == "large" and #ingredients == 3 then
				recipe.size = "small"
			end

			if not table.contains(recipe.station, data.station) then
				table.insert(recipe.station, data.station)
				table.sort(recipe.station, function (a, b) return b < a end)
			end

			local known_index = IsKnownIngredients(recipe.recipes, ingredients)
			if known_index ~= nil then
				if known_index > 1 then
					table.remove(recipe.recipes, known_index)
					table.insert(recipe.recipes, 1, ingredients)
				end
			else
				if #recipe.recipes >= MAX_RECIPES then
					table.remove(recipe.recipes, #recipe.recipes)
				end
				table.insert(recipe.recipes, 1, ingredients)
			end

			self.dirty = true
		end
	end

	local data = deepcopy(data)
	data.new_recipe = new_recipe
	TheWorld:PushEvent("quagmire_notifyrecipeupdated", data)

	self:Save()
end


local function OnRecipeAppraised(self, data)
	local recipe = self.recipes[tostring(data.product)]
	if recipe ~= nil then
		local coins = {}
		coins.coin1 = data.coins[1]
		coins.coin2 = (not(data.coins[2] == 0 and data.coins[3] == 0 and data.coins[4] == 0)) and data.coins[2] or nil
		coins.coin3 = (not(data.coins[3] == 0 and data.coins[4] == 0)) and data.coins[3] or nil
		coins.coin4 = data.coins[4] ~= 0 and data.coins[4] or nil
		
		recipe[data.silverdish and "silver_value" or "base_value"] = coins

		if data.matchedcraving ~= nil and not table.contains(recipe.tags, data.matchedcraving) then
			if recipe.tags == nil then
				recipe.tags = {}
			end
			table.insert(recipe.tags, data.matchedcraving)
		end

		if data.snackpenalty and not table.contains(recipe.tags, "snack") then
			if recipe.tags == nil then
				recipe.tags = {}
			end
			table.insert(recipe.tags, "snack")
		end

		self.dirty = true
	end

	self:Save()
end


function QuagmireRecipeBook:RegisterWorld(world)
	world:ListenForEvent("quagmire_recipediscovered", function(w, data) OnRecipeDiscovered(self, data) end)
	world:ListenForEvent("quagmire_recipeappraised", function(w, data) OnRecipeAppraised(self, data) end)
end

return QuagmireRecipeBook
