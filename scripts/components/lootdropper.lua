local LootDropper = Class(function(self, inst)
    self.inst = inst
    self.numrandomloot = nil
    self.randomloot = nil
    self.chancerandomloot = nil
    self.totalrandomweight = nil
    self.chanceloot = nil
    self.ifnotchanceloot = nil
    self.droppingchanceloot = false
    self.loot = nil
    self.chanceloottable = nil

    self.trappable = true

	self.lootfn = nil
    
end)

LootTables = {}
function SetSharedLootTable(name, table)
	LootTables[name] = table
end

function LootDropper:SetChanceLootTable(name)
	self.chanceloottable = name
end

function LootDropper:SetLoot( loots )
    self.loot = loots
    self.chanceloot = nil
    self.randomloot = nil
    self.numrandomloot = nil
end

function LootDropper:SetLootSetupFn( fn )
	self.lootsetupfn = fn
end

function LootDropper:AddRandomLoot( prefab, weight)
    if not self.randomloot then
		self.randomloot = {}
		self.totalrandomweight = 0
	end
	
    table.insert(self.randomloot, {prefab=prefab,weight=weight} )
    self.totalrandomweight = self.totalrandomweight + weight
end

-- This overrides the normal loot table while haunted
function LootDropper:AddRandomHauntedLoot( prefab, weight)
	if not self.randomhauntedloot then
		self.randomhauntedloot = {}
		self.totalhauntedrandomweight = 0
	end
	
    table.insert(self.randomhauntedloot, {prefab=prefab,weight=weight} )
    self.totalhauntedrandomweight = self.totalhauntedrandomweight + weight
end

function LootDropper:AddChanceLoot( prefab, chance)
    if not self.chanceloot then
		self.chanceloot = {}
	end
    table.insert(self.chanceloot, {prefab=prefab,chance=chance} )
end

function LootDropper:AddIfNotChanceLoot(prefab)
	if not self.ifnotchanceloot then
		self.ifnotchanceloot = {}
	end
	table.insert(self.ifnotchanceloot, {prefab=prefab})
end

function LootDropper:PickRandomLoot()
	if self.inst.components.hauntable and self.inst.components.hauntable.haunted and self.totalhauntedrandomweight and self.totalhauntedrandomweight > 0 and self.randomhauntedloot then
		local rnd = math.random()*self.totalhauntedrandomweight
        for k,v in pairs(self.randomhauntedloot) do
            rnd = rnd - v.weight
            if rnd <= 0 then
                return v.prefab
            end
        end
    elseif self.totalrandomweight and self.totalrandomweight > 0 and self.randomloot then
        local rnd = math.random()*self.totalrandomweight
        for k,v in pairs(self.randomloot) do
            rnd = rnd - v.weight
            if rnd <= 0 then
                return v.prefab
            end
        end
    end
end

function LootDropper:GenerateLoot()
    local loots = {}

	if self.lootsetupfn then
		self.lootsetupfn(self)
	end
    
    if self.numrandomloot and math.random() <= (self.chancerandomloot or 1) then
		for k = 1, self.numrandomloot do
		    local loot = self:PickRandomLoot()
		    if loot then
			    table.insert(loots, loot)
			end
		end
	end
    
    if self.chanceloot then
		for k,v in pairs(self.chanceloot) do
			if math.random() < v.chance then
				table.insert(loots, v.prefab)
				self.droppingchanceloot = true
			end
		end
	end

    if self.chanceloottable then
    	local loot_table = LootTables[self.chanceloottable]
    	if loot_table then
    		for i, entry in ipairs(loot_table) do
    			local prefab = entry[1]
    			local chance = entry[2]    			
				if math.random() <= chance then
					table.insert(loots, prefab)
					self.droppingchanceloot = true
				end
			end
		end
	end

	if not self.droppingchanceloot and self.ifnotchanceloot then
		self.inst:PushEvent("ifnotchanceloot")
		for k,v in pairs(self.ifnotchanceloot) do
			table.insert(loots, v.prefab)
		end
	end


    
    if self.loot then
		for k,v in ipairs(self.loot) do
			table.insert(loots, v)
		end
	end
	
	local recipe = AllRecipes[self.inst.prefab]

	if recipe then
		local percent = 1

		if self.inst.components.finiteuses then
			percent = self.inst.components.finiteuses:GetPercent()
		end

		for k,v in ipairs(recipe.ingredients) do
			local amt = math.ceil( (v.amount * TUNING.HAMMER_LOOT_PERCENT) * percent)
			if self.inst:HasTag("burnt") then 
				amt = math.ceil( (v.amount * TUNING.BURNT_HAMMER_LOOT_PERCENT) * percent)
			end
			for n = 1, amt do
				table.insert(loots, v.type)
			end
		end
	end
    
	if self.inst:HasTag("burnt") and math.random() < .4 then
		table.insert(loots, "charcoal") -- Add charcoal to loot for burnt structures
	end

    return loots
end

local function SplashOceanLoot(loot)
    if not (loot.components.inventoryitem ~= nil and loot.components.inventoryitem:IsHeld()) and
        not loot:IsOnValidGround() then
        SpawnPrefab("splash_ocean").Transform:SetPosition(loot.Transform:GetWorldPosition())
        if loot:HasTag("irreplaceable") then
            loot.Transform:SetPosition(FindSafeSpawnLocation(loot.Transform:GetWorldPosition()))
        else
            loot:Remove()
        end
    end
end

function LootDropper:SpawnLootPrefab(lootprefab, pt)
    if lootprefab ~= nil then
        local loot = SpawnPrefab(lootprefab)
        if loot ~= nil then
            if pt == nil then
                pt = self.inst:GetPosition()
            end

            loot.Transform:SetPosition(pt:Get())

            if loot.components.inventoryitem ~= nil then
                if self.inst.components.inventoryitem ~= nil then
                    loot.components.inventoryitem:InheritMoisture(self.inst.components.inventoryitem:GetMoisture(), self.inst.components.inventoryitem:IsWet())
                else
                    loot.components.inventoryitem:InheritMoisture(TheWorld.state.wetness, TheWorld.state.iswet)
                end
            end

            if loot.Physics ~= nil then
                local angle = math.random() * 2 * PI
                local speed = math.random() * 2
                if loot:IsAsleep() then
                    local radius = .5 * speed + (self.inst ~= nil and self.inst.Physics ~= nil and (loot.Physics:GetRadius() or 1) + (self.inst.Physics:GetRadius() or 1) or 0)
                    loot.Transform:SetPosition(
                        pt.x + math.cos(angle) * radius,
                        0,
                        pt.z + math.sin(angle) * radius
                    )

                    SplashOceanLoot(loot)
                else
                    loot.Physics:SetVel(speed * math.cos(angle), GetRandomWithVariance(8, 4), speed * math.sin(angle))

                    if self.inst ~= nil and self.inst.Physics ~= nil then
                        local radius = (loot.Physics:GetRadius() or 1) + (self.inst.Physics:GetRadius() or 1)
                        loot.Transform:SetPosition(
                            pt.x + math.cos(angle) * radius,
                            pt.y,
                            pt.z + math.sin(angle) * radius
                        )
                    end

                    loot:DoTaskInTime(1, SplashOceanLoot)
                end
            end

            return loot
        end
    end
end

function LootDropper:DropLoot(pt)
    local prefabs = self:GenerateLoot()
    if not self.inst.components.fueled and self.inst.components.burnable and self.inst.components.burnable:IsBurning() then
        for k,v in pairs(prefabs) do
            local cookedAfter = v.."_cooked"
            local cookedBefore = "cooked"..v
            if PrefabExists(cookedAfter) then
                prefabs[k] = cookedAfter
            elseif PrefabExists(cookedBefore) then
                prefabs[k] = cookedBefore 
            else             
                prefabs[k] = "ash"               
            end
        end
    end
    for k,v in pairs(prefabs) do
        self:SpawnLootPrefab(v, pt)
    end
end

return LootDropper
