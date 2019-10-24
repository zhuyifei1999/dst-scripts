local MakePlayerCharacter = require("prefabs/player_common")

local assets =
{
    Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
    Asset("SOUND", "sound/wurt.fsb"),
    Asset("ANIM", "anim/player_idles_wurt.zip"),
}

local prefabs =
{
	"wurt_tentacle_warning",
}

local start_inv =
{
    default =
    {
    },
}

for k, v in pairs(TUNING.GAMEMODE_STARTING_ITEMS) do
	start_inv[string.lower(k)] = v.WURT
end
prefabs = FlattenTree({ prefabs, start_inv }, true)

local function RoyalUpgrade(inst, silent)
    inst.components.health:SetMaxHealth(TUNING.WURT_HEALTH_KINGBONUS)
    inst.components.hunger:SetMax(TUNING.WURT_HUNGER_KINGBONUS)
    inst.components.sanity:SetMax(TUNING.WURT_SANITY_KINGBONUS)


    if not silent and not inst.royal then
    	inst.royal = true
    	inst.components.talker:Say(GetString(inst, "ANNOUNCE_KINGCREATED"))        
        inst.sg:PushEvent("powerup_wurt")
        inst.SoundEmitter:PlaySound("dontstarve/characters/wurt/transform_to")
    end
end

local function RoyalDowngrade(inst, silent)
    inst.components.health:SetMaxHealth(TUNING.WURT_HEALTH)
    inst.components.hunger:SetMax(TUNING.WURT_HUNGER)
    inst.components.sanity:SetMax(TUNING.WURT_SANITY)

    if not silent and inst.royal then
    	inst.royal = nil
        inst.components.talker:Say(GetString(inst, "ANNOUNCE_KINGDESTROYED"))
        inst.sg:PushEvent("powerdown_wurt")
        inst.SoundEmitter:PlaySound("dontstarve/characters/wurt/transform_from")
    end
end

local function UpdateTentacleWarnings(inst)
	local disable = (inst.replica.inventory ~= nil and not inst.replica.inventory:IsVisible())

	if not disable then
		local old_warnings = {}
		for t, w in pairs(inst._active_warnings) do
			old_warnings[t] = w
		end

		local x, y, z = inst.Transform:GetWorldPosition()
		local warn_dist = 15
		local tentacles = TheSim:FindEntities(x, y, z, warn_dist, {"tentacle", "invisible"})
		for i, t in ipairs(tentacles) do
			local p1x, p1y, p1z = inst.Transform:GetWorldPosition()
			local p2x, p2y, p2z = t.Transform:GetWorldPosition()
			local dist = VecUtil_Length(p1x - p2x, p1z - p2z)

			if t.replica.health ~= nil and not t.replica.health:IsDead() then
				if inst._active_warnings[t] == nil then
					local fx = SpawnPrefab("wurt_tentacle_warning")
					fx.entity:SetParent(t.entity)
					inst._active_warnings[t] = fx
				else
					old_warnings[t] = nil
				end
			end
		end

		for t, w in pairs(old_warnings) do
			inst._active_warnings[t] = nil
			if w:IsValid() then
				ErodeAway(w, 0.5)
			end
		end
	elseif next(inst._active_warnings) ~= nil then
		for t, w in pairs(inst._active_warnings) do
			if w:IsValid() then
				w:Remove()
			end
		end
		inst._active_warnings = {}
	end
end

local function DisableTentacleWarning(inst)
	if inst.tentacle_warning_task ~= nil then
		inst.tentacle_warning_task:Cancel()
		inst.tentacle_warning_task = nil
	end
			
	for t, w in pairs(inst._active_warnings) do
		if w:IsValid() then
			w:Remove()
		end
	end
	inst._active_warnings = {}
end

local function EnableTentacleWarning(inst)
	if inst.player_classified ~= nil then
		inst:ListenForEvent("playerdeactivated", DisableTentacleWarning)
		if inst.tentacle_warning_task == nil then
			inst.tentacle_warning_task = inst:DoPeriodicTask(0.1, UpdateTentacleWarnings)
		end
	else
	    inst:RemoveEventCallback("playeractivated", EnableTentacleWarning)
	end
end

local function SetGhostMode(inst, isghost)
    if isghost then
		DisableTentacleWarning(inst)
        inst._SetGhostMode(inst, true)
    else
        inst._SetGhostMode(inst, false)
		EnableTentacleWarning(inst)
    end
end

-- PERUSE BOOKS
local function peruse_brimstone(inst)
    inst.components.sanity:DoDelta(-TUNING.SANITY_LARGE)
end
local function peruse_birds(inst)
    inst.components.sanity:DoDelta(TUNING.SANITY_HUGE)
end
local function peruse_tentacles(inst)
    inst.components.sanity:DoDelta(TUNING.SANITY_HUGE)
end
local function peruse_sleep(inst)
    inst.components.sanity:DoDelta(TUNING.SANITY_LARGE)
end
local function peruse_gardening(inst)
    inst.components.sanity:DoDelta(-TUNING.SANITY_LARGE)
end

local function common_postinit(inst)
    inst:AddTag("merm")
    inst:AddTag("mermguard")
    inst:AddTag("mermfluent")
    inst:AddTag("merm_builder")
    inst:AddTag("wet")
    inst:AddTag("stronggrip")
    inst:AddTag("aspiring_bookworm")

    inst.customidleanim = "idle_wurt"

    if TheNet:GetServerGameMode() == "lavaarena" then
        --do nothing
    elseif TheNet:GetServerGameMode() == "quagmire" then
        inst:AddTag("quagmire_shopper")
    else
		if not TheNet:IsDedicated() then
			inst._active_warnings = {}
			inst:ListenForEvent("playeractivated", EnableTentacleWarning)
		end
	end
end

local function master_postinit(inst)
    inst.starting_inventory = start_inv[TheNet:GetServerGameMode()] or start_inv.default

    inst:AddComponent("reader")

    inst:AddComponent("foodaffinity")
    inst.components.foodaffinity:AddFoodtypeAffinity(FOODTYPE.VEGGIE, 1.33)
    inst.components.foodaffinity:AddPrefabAffinity  ("kelp",          1.33)
    inst.components.foodaffinity:AddPrefabAffinity  ("kelp_cooked",   1.33)
    inst.components.foodaffinity:AddPrefabAffinity  ("kelp_dried",    1.33)
    inst.components.foodaffinity:AddPrefabAffinity  ("durian",        1.6 )
    inst.components.foodaffinity:AddPrefabAffinity  ("durian_cooked", 1.6 )

    inst:AddComponent("itemaffinity")
    inst.components.itemaffinity:AddAffinity(nil, "fish", TUNING.DAPPERNESS_MED, 1)

    if inst.components.eater ~= nil then
        inst.components.eater:SetDiet({ FOODGROUP.VEGETARIAN }, { FOODGROUP.VEGETARIAN })
    end

    inst.components.health:SetMaxHealth(TUNING.WURT_HEALTH)
    inst.components.hunger:SetMax(TUNING.WURT_HUNGER)
    inst.components.sanity:SetMax(TUNING.WURT_SANITY)

	inst.components.locomotor:SetFasterOnGroundTile(GROUND.MARSH, true)

    inst:ListenForEvent("onmermkingcreated",   function() RoyalUpgrade(inst)   end, TheWorld)
    inst:ListenForEvent("onmermkingdestroyed", function() RoyalDowngrade(inst) end, TheWorld)

    inst.peruse_brimstone = peruse_brimstone
    inst.peruse_birds = peruse_birds
    inst.peruse_tentacles = peruse_tentacles
    inst.peruse_sleep = peruse_sleep
    inst.peruse_gardening = peruse_gardening  

    inst:DoTaskInTime(0, function() 
        if TheWorld.components.mermkingmanager and TheWorld.components.mermkingmanager:HasKing() then
            RoyalUpgrade(inst)
        end
    end)
end

return MakePlayerCharacter("wurt", prefabs, assets, common_postinit, master_postinit)