local assets =
{
    Asset("ANIM", "anim/hermitcrab_home.zip"),
    Asset("MINIMAP_IMAGE", "hermitcrab_home"),
    Asset("MINIMAP_IMAGE", "hermitcrab_home2"),
}

local prefabs =
{
    "gridplacer_group_outline",
}

--requires max friendlevels
--recipe unlocks when decoration reaches or exceeds maxscore
--recipe is locked again if dropped below minscore

-- NOTE: Shellweaver 2nd tier unlocks at 40 points
local UNLOCKABLE_RECIPES =
{
	["hermitcrab_lightpost"] = { minscore = 5, maxscore = 10 },
    ["hermitcrab_teashop"] = { minscore = 15, maxscore = 25 },
    ["hermithotspring_constr"] = { minscore = 50, maxscore = 60 },
    ["meatrack_hermit_multi"] = { minscore = 80, maxscore = 90 },
}
--"hermithouse_ornament" unlocks with "hermithouse2"

--lvl5 aka "hermithouse2"
local UNLOCKABLE_LVL5_CONSTR = { minscore = 0, maxscore = 0 }


local function _dbg_print(...)
	print("[hermithouse.lua]:", ...)
end

local function onsave(inst, data)
	data.highfriendlevel = inst:HasTag("highfriendlevel") or nil
 end

local function onload(inst, data)
	if data and data.highfriendlevel then
		inst:AddTag("highfriendlevel")
	end
end

--------------------------------------------------------------------------

local function lvl1_master_postinit(inst)
    SetLunarHailBuildupAmountSmall(inst)
end

--------------------------------------------------------------------------

local function lvl2_master_postinit(inst)
    SetLunarHailBuildupAmountSmall(inst)
end

--------------------------------------------------------------------------

local function lvl3_master_postinit(inst)
    SetLunarHailBuildupAmountMedium(inst)
end

--------------------------------------------------------------------------

local function lvl4_SetConstructionUnlocked(constructionsite, unlock)
	if constructionsite:IsEnabled() ~= unlock then
		if unlock then
			_dbg_print("+Unlocked hermithouse2 construction")
			constructionsite:Enable()
		else
			_dbg_print("-Disabled hermithouse2 construction")
			constructionsite:Disable()
		end
	end
end

local function SetRecipeUnlocked(craftingstation, recipename, unlock)
	if craftingstation:KnowsItem(recipename) ~= unlock then
		if unlock then
			_dbg_print("+Unlocked recipe for "..STRINGS.NAMES[string.upper(recipename)])
			craftingstation:LearnItem(recipename, recipename)
		else
			_dbg_print("-Disabled recipe for "..STRINGS.NAMES[string.upper(recipename)])
			craftingstation:ForgetItem(recipename)
		end
	end
end

local function ClearAllUnlockedRecipes(inst)
	local craftingstation = inst._hermitcrab and inst._hermitcrab.components.craftingstation
	if craftingstation then
		for k in pairs(UNLOCKABLE_RECIPES) do
			SetRecipeUnlocked(craftingstation, k, false)
		end
		SetRecipeUnlocked(craftingstation, "hermithouse_ornament", false)
	end
end

local function CheckUnlocks(inst)
	local constructionsite = inst.components.constructionsite
	local friendlevels = inst._hermitcrab and inst._hermitcrab.components.friendlevels
	if friendlevels and friendlevels:GetLevel() >= friendlevels:GetMaxLevel() and inst.components.pearldecorationscore:IsEnabled() then
		local score = inst.components.pearldecorationscore:GetScore()
		if constructionsite then
			lvl4_SetConstructionUnlocked(constructionsite, score >= (constructionsite:IsEnabled() and UNLOCKABLE_LVL5_CONSTR.minscore or UNLOCKABLE_LVL5_CONSTR.maxscore))
		end
		local craftingstation = inst._hermitcrab.components.craftingstation
		if craftingstation then
			for k, v in pairs(UNLOCKABLE_RECIPES) do
				SetRecipeUnlocked(craftingstation, k, score >= (craftingstation:KnowsItem(k) and v.minscore or v.maxscore))
			end
			SetRecipeUnlocked(craftingstation, "hermithouse_ornament", inst.components.container ~= nil)
		end
	else
		if constructionsite then
			lvl4_SetConstructionUnlocked(constructionsite, false)
		end
		ClearAllUnlockedRecipes(inst)
	end
end

local function StartTrackingHermitCrab(inst, hermitcrab)
	inst.OnEntityWake = nil

	hermitcrab = hermitcrab or inst.components.spawner.child
	if hermitcrab and inst._hermitcrab ~= hermitcrab then
		if inst._hermitcrab and inst._hermitcrab:IsValid() then
			inst:RemoveEventCallback("friend_level_changed", inst._checkunlocks, inst._hermitcrab)
			ClearAllUnlockedRecipes(inst)
		end
		inst._hermitcrab = hermitcrab
		_dbg_print(string.format("<%s> now tracking <%s>", tostring(inst), tostring(hermitcrab)))
		inst:ListenForEvent("friend_level_changed", inst._checkunlocks, hermitcrab)
		CheckUnlocks(inst)
	end
end

local function StopTrackingHermitCrab(inst, hermitcrab)
	if inst._hermitcrab == hermitcrab and hermitcrab then
		_dbg_print(string.format("<%s> no longer tracking <%s>", tostring(inst), tostring(hermitcrab)))
		inst:RemoveEventCallback("friend_level_changed", inst._checkunlocks, hermitcrab)
		ClearAllUnlockedRecipes(inst)
		inst._hermitcrab = nil
	end
end

local function SetupScoreTracking(inst)
	inst.components.spawner:SetOnSpawnedFn(StartTrackingHermitCrab)
	inst.components.spawner:SetOnKilledFn(StopTrackingHermitCrab)

	inst._checkunlocks = function() CheckUnlocks(inst) end
	inst:ListenForEvent("pearldecorationscore_updatestatus", inst._checkunlocks, TheWorld)
	inst:ListenForEvent("pearldecorationscore_updatescore", inst._checkunlocks, TheWorld)
end

local function lvl4_OnSave(inst, data)
	onsave(inst, data)
	data.construction = inst.components.constructionsite:IsEnabled() or nil
end

local function lvl4_OnLoadPostPass(inst, ents, data)
	if data and data.construction then
		inst.components.constructionsite:Enable()
	end
	inst:StartTrackingHermitCrab()
end

local function lvl4_master_postinit(inst)
    SetLunarHailBuildupAmountLarge(inst)
	inst.components.constructionsite:Disable()
	SetupScoreTracking(inst)

	inst.OnSave = lvl4_OnSave
	inst.OnLoadPostPass = lvl4_OnLoadPostPass
	inst.OnEntityWake = StartTrackingHermitCrab
	inst.StartTrackingHermitCrab = StartTrackingHermitCrab
end

--------------------------------------------------------------------------

local function lvl5_OnLoadPostPass(inst)--, ents, data)
	inst:StartTrackingHermitCrab()
end

local function lvl5_master_postinit(inst)
    SetLunarHailBuildupAmountLarge(inst)
	SetupScoreTracking(inst)

	inst.OnLoadPostPass = lvl5_OnLoadPostPass
	inst.OnEntityWake = StartTrackingHermitCrab
	inst.StartTrackingHermitCrab = StartTrackingHermitCrab
end

--------------------------------------------------------------------------

local construction_data = {
	{level = 1, name = "hermithouse_construction1", construction_product = "hermithouse_construction2", master_postinit = lvl1_master_postinit },
	{level = 2, name = "hermithouse_construction2", construction_product = "hermithouse_construction3", master_postinit = lvl2_master_postinit },
	{level = 3, name = "hermithouse_construction3", construction_product = "hermithouse", master_postinit = lvl3_master_postinit },
	{level = 4, name = "hermithouse",				construction_product = "hermithouse2", master_postinit = lvl4_master_postinit },
}

local function displaynamefn(inst)
    return inst:HasTag("highfriendlevel") and STRINGS.NAMES.HERMITHOUSE_PEARL or STRINGS.NAMES.HERMITHOUSE
end

local function LightsOn(inst)
    if not inst:HasTag("burnt") and not inst.lightson then
        inst.Light:Enable(true)
        inst.SoundEmitter:PlaySound("hookline_2/characters/hermit/house/light_on")
        inst.lightson = true

        local build_name = inst.AnimState:GetSkinBuild()
        if inst._window ~= nil then
            if build_name ~= "" then
                inst._window.AnimState:SetSkin(build_name)
            end
            inst._window.AnimState:PlayAnimation("windowlight_idle", true)
            inst._window:Show()
        end
        if inst._windowsnow ~= nil then
            if build_name ~= "" then
                inst._windowsnow.AnimState:SetSkin(build_name)
            end
            inst._windowsnow.AnimState:PlayAnimation("windowsnow_idle", true)
            inst._windowsnow:Show()
        end
    end
end

local function LightsOff(inst)
    if not inst:HasTag("burnt") and inst.lightson then
        inst.Light:Enable(false)
        inst.SoundEmitter:PlaySound("hookline_2/characters/hermit/house/light_off")
        inst.lightson = false
        if inst._window ~= nil then
            inst._window:Hide()
        end
        if inst._windowsnow ~= nil then
            inst._windowsnow:Hide()
        end
    end
end

local function onoccupieddoortask(inst)
    inst.doortask = nil
    if not inst.nolight then
        LightsOn(inst)
    end
end

local function onoccupied(inst, child)
    if not inst:HasTag("burnt") then
        inst.SoundEmitter:PlaySound("hookline_2/characters/hermit/house/inside_LP", "hermitsound")

        if inst.level > 1 then
            inst.SoundEmitter:PlaySound("hookline_2/characters/hermit/house/stage2_door")
        else
            inst.SoundEmitter:PlaySound("hookline_2/characters/hermit/house/stage1_door")
        end

        if inst.doortask ~= nil then
            inst.doortask:Cancel()
        end
        inst.doortask = inst:DoTaskInTime(1, onoccupieddoortask)
    end
end

local function onvacate(inst, child)
    if not inst:HasTag("burnt") then
        if inst.doortask ~= nil then
            inst.doortask:Cancel()
            inst.doortask = nil
        end

        if inst.level > 1 then
            inst.SoundEmitter:PlaySound("hookline_2/characters/hermit/house/stage2_door")
        else
            inst.SoundEmitter:PlaySound("hookline_2/characters/hermit/house/stage1_door")
        end

        inst.SoundEmitter:KillSound("hermitsound")
        LightsOff(inst)

        if child ~= nil then
            local child_platform = child:GetCurrentPlatform()
            if (child_platform == nil and not child:IsOnValidGround()) then
                local fx = SpawnPrefab("splash_sink")
                fx.Transform:SetPosition(child.Transform:GetWorldPosition())

                child:Remove()
            else
                if child.components.health ~= nil then
                    child.components.health:SetPercent(1)
                end
			    child:PushEvent("onvacatehome")
            end
        end
    end
end

local function OnConstructed(inst, doer)
    local concluded = true
    for _, v in ipairs(CONSTRUCTION_PLANS[inst.prefab] or {}) do
        if inst.components.constructionsite:GetMaterialCount(v.type) < v.amount then
            concluded = false
            break
        end
    end

	if concluded then
        local ishome =  inst.components.spawner:IsOccupied()
        inst.components.spawner:ReleaseChild()
        local child = inst.components.spawner.child -- NOTES(JBK): This must be after ReleaseChild for entity safety because it will create a new one if it no longer exists.
        local pearlscore_enabled = inst.components.pearldecorationscore and inst.components.pearldecorationscore.enabled

		if inst.components.pearldecorationscore then
			--V2C: Normally, if the house is removed, we would send out an event to all structures
			--     that used MakeHermitCrabAreaListener so that they can react accordingly. But in
			--     this case, we don't want to do that, because a new house should be replacing it
			--     as seamlessly as possible.
			inst.components.pearldecorationscore:FlagForConstructionRemoval()
		end

        local new_house = ReplacePrefab(inst, inst._construction_product)
        new_house.SoundEmitter:PlaySound("hookline_2/characters/hermit/house/stage"..new_house.level.."_place")

        new_house.components.spawner:TakeOwnership(child)
        child:PushEvent("home_upgraded",{house=new_house,doer=doer})
        if ishome then
            new_house.components.spawner:GoHome(child)
        end
        new_house.AnimState:PlayAnimation("stage"..new_house.level.."_placing")
        new_house.AnimState:PushAnimation("idle_stage"..new_house.level)
        if inst:HasTag("highfriendlevel") then
            new_house:AddTag("highfriendlevel")
        end

		if new_house.components.container and inst.components.container == nil then
			local ornament = SpawnPrefab("hermithouse_ornament")
			if not new_house.components.container:GiveItem(ornament, 2, nil, false) then
				ornament:Remove()
			end
		end

		if pearlscore_enabled then
			if new_house.components.pearldecorationscore then
				new_house.components.pearldecorationscore:Enable()
			else
				assert(BRANCH ~= "dev")
				--shouldn't reach here?
				--FlagForConstructionRemoval() above, suppressed this event assuming
				--the new house would re-enable scoring.
				TheWorld:PushEvent("pearldecorationscore_updatestatus")
			end
		end

		if new_house.StartTrackingHermitCrab then
			new_house:StartTrackingHermitCrab()
		end
    end
end

local function onstartdaydoortask(inst)
    inst.doortask = nil
    if not inst:HasTag("burnt") then
        inst.components.spawner:ReleaseChild()
    end
end

local function onstartdaylighttask(inst)
    if inst:IsLightGreaterThan(0.8) then -- they have their own light! make sure it's brighter than that out.
        LightsOff(inst)
        inst.doortask = inst:DoTaskInTime(1 + math.random() * 2, onstartdaydoortask)
    elseif TheWorld.state.iscaveday then
        inst.doortask = inst:DoTaskInTime(1 + math.random() * 2, onstartdaylighttask)
    else
        inst.doortask = nil
    end
end

local function OnStartDay(inst)
    --print(inst, "OnStartDay")
    if not inst:HasTag("burnt")
        and inst.components.spawner:IsOccupied() then

        if inst.doortask ~= nil then
            inst.doortask:Cancel()
        end
        inst.doortask = inst:DoTaskInTime(1 + math.random() * 2, onstartdaylighttask)
    end
end

local function spawncheckday(inst)
    inst.inittask = nil
    inst:WatchWorldState("startcaveday", OnStartDay)
    if inst.components.spawner ~= nil and inst.components.spawner:IsOccupied() then
        if TheWorld.state.iscaveday or
            (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
            inst.components.spawner:ReleaseChild()
        else
            onoccupieddoortask(inst)
        end
    end
end

local function oninit(inst)
    inst.inittask = inst:DoTaskInTime(math.random(), spawncheckday)
    if inst.components.spawner ~= nil and
        inst.components.spawner.child == nil and
        inst.components.spawner.childname ~= nil and
        not inst.components.spawner:IsSpawnPending() then
        local child = SpawnPrefab(inst.components.spawner.childname)
        if child ~= nil then
            inst.components.spawner:TakeOwnership(child)
            inst.components.spawner:GoHome(child)
			if child.retrofitconstuctiontasks ~= nil then
				child:retrofitconstuctiontasks(inst.prefab)
			end
			if inst.StartTrackingHermitCrab then
				inst:StartTrackingHermitCrab()
			end
        end
    end

	if inst.components.spawner.child ~= nil and inst.components.spawner.child.retrofitconstuctiontasks ~= nil then
		inst.components.spawner.child:retrofitconstuctiontasks(inst.prefab)
	end
end

local function dowind(inst)
    if inst.AnimState:IsCurrentAnimation("idle_stage"..inst.level) then
        inst.AnimState:PlayAnimation("idle_stage"..inst.level.."_wind")
        inst.AnimState:PushAnimation("idle_stage"..inst.level)
    end
	if inst.ornamentfx then
		for _, v in pairs(inst.ornamentfx) do
			v:dowind()
		end
	end
	inst:DoTaskInTime(math.random()*5, dowind)
end

local function getstatus(inst)
    if inst.prefab ~= "hermithouse_construction1"  then
        return "BUILTUP"
    end
end

--------------------------------------------------------------------------

local function MakeOrnamentFx(inst, item, slot)
	return item:CloneAndFollowSymbol(inst, "follow_ornament_"..tostring(slot), nil, nil, nil, true)
end

local function AddDecor(inst, data)
	if data and data.slot and data.item then
		if data.slot == 3 or data.slot == 4 then
			inst.AnimState:Hide("laundry_"..tostring(data.slot))
		end
		if inst.ornamentfx[data.slot] then
			inst.ornamentfx[data.slot]:Remove()
		end
		inst.ornamentfx[data.slot] = MakeOrnamentFx(inst, data.item, data.slot)
	end
end

local function RemoveDecor(inst, data)
	if data and data.slot then
		if data.slot == 3 or data.slot == 4 then
			inst.AnimState:Show("laundry_"..tostring(data.slot))
		end
		if inst.ornamentfx[data.slot] then
			inst.ornamentfx[data.slot]:Remove()
			inst.ornamentfx[data.slot] = nil
		end
	end
end

local function RefreshDecor(inst, item)
	local slot = inst.components.container:GetItemSlot(item)
	if slot and inst.ornamentfx[slot] then
		inst.ornamentfx[slot]:Remove()
		inst.ornamentfx[data.slot] = MakeOrnamentFx(inst, item, slot)
	end
end

--------------------------------------------------------------------------

local function OnEnableHelper(inst, enabled)
    if enabled then
        local x, y, z = inst.Transform:GetWorldPosition()
        local tx, tz = TheWorld.Map:GetTileCoordsAtPoint(x, y, z)

        if inst.cached_coords.x ~= tx or inst.cached_coords.z ~= tz then
            inst.cached_coords.x = tx
            inst.cached_coords.z = tz

            inst.group_outline = inst.group_outline or SpawnPrefab("gridplacer_group_outline")

            local occupation_grid = GetHermitCrabOccupiedGrid(tx, tz)
            for index in pairs(occupation_grid.grid) do
                local gx, gz = inst.group_outline.outline_grid:GetXYFromIndex(index)
                if occupation_grid:GetDataAtIndex(index) then
                    inst.group_outline:PlaceGrid(gx, gz)
                end
            end

            for index in pairs(inst.group_outline.outline_grid.grid) do
                local gx, gz = inst.group_outline.outline_grid:GetXYFromIndex(index)
                if not occupation_grid:GetDataAtIndex(index) then
                    inst.group_outline:RemoveGrid(gx, gz)
                end
            end
        end
    elseif inst.group_outline ~= nil then -- Reset
        inst.cached_coords.x = -1
        inst.cached_coords.z = -1
        inst.group_outline:Remove()
        inst.group_outline = nil
    end
end

local function CanEnableHelper(inst)
    -- NOTE: Kind of a hack. Just check if we're not on Hermit island, assume we've been evicted.
    return IsInValidHermitCrabDecorArea(inst)
end

--------------------------------------------------------------------------

local HERMIT_HOMES = {}
local function IsPointWithinHermitArea(home, pt)
    if TheWorld.ismastersim then
        if home.components.pearldecorationscore:IsPointWithin(pt.x, pt.y, pt.z, true) then
            return true
        end
    else
        local tx, ty = TheWorld.Map:GetTileCoordsAtPoint(pt:Get())
        if home.group_outline and home.group_outline.outline_grid:GetDataAtPoint(tx, ty) then
            return true
        end
    end
end
function CanDeployHermitDecorationAtPoint(pt, radius) -- Global to use in other places. Supports client and server.
    for k, v in ipairs(HERMIT_HOMES) do
        local failed
        if radius and radius > 0 then
            for i = 1, 8 do
                local theta = TWOPI * i / 8
                local px, pz = pt.x + radius * math.cos(theta), pt.z - radius * math.sin(theta)
                if not IsPointWithinHermitArea(v, Vector3(px, 0, pz)) then
                    failed = true
                    break
                end
            end
        end

        if not failed and IsPointWithinHermitArea(v, pt) then
            return true
        end
    end
    --
    return false
end

local function OnRemove(inst)
    table.removearrayvalue(HERMIT_HOMES, inst)
end

--------------------------------------------------------------------------

local function MakeHermitCrabHouse(name, client_postinit, master_postinit, house_data)
    local is_built_home = name == "hermithouse" or name == "hermithouse2"
	local is_decoratable = house_data == nil

	local function fn()

        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddLight()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()

		inst.MiniMapEntity:SetIcon("hermitcrab_home2.png")

        inst:AddTag("structure")
		if is_decoratable then
			inst:AddTag("decoratable")
		end

		inst.level = house_data and house_data.level or 5

		inst:SetPhysicsRadiusOverride(1.5)
		MakeObstaclePhysics(inst, inst.physicsradiusoverride)

		inst.Light:SetFalloff(1)
		inst.Light:SetIntensity(.5)
		inst.Light:SetRadius(1)
		inst.Light:Enable(false)
		inst.Light:SetColour(180/255, 195/255, 50/255)

		inst.AnimState:SetBank("hermitcrab_home")
		inst.AnimState:SetBuild("hermitcrab_home")
		inst.AnimState:PlayAnimation("idle_stage"..tostring(inst.level), true)
        inst.scrapbook_anim = "idle_stage1"

		if house_data then
			--constructionsite (from constructionsite component) added to pristine state for optimization
			inst:AddTag("constructionsite")
		end

        if is_built_home then
            --Dedicated server does not need deployhelper
            if not TheNet:IsDedicated() then
                inst:AddComponent("deployhelper")
                inst.components.deployhelper.onenablehelper = OnEnableHelper
                inst.components.deployhelper.canenablehelper = CanEnableHelper

                inst.cached_coords = { x = - 1, z = - 1 }
            end
            table.insert(HERMIT_HOMES, inst)
            inst:ListenForEvent("onremove", OnRemove)
        end

        inst.displaynamefn = displaynamefn

		inst:AddTag("antlion_sinkhole_blocker")
        inst:AddTag("hermithouse")

        inst.scrapbook_proxy = "hermithouse"

        local lightpostpartner = inst:AddComponent("lightpostpartner")
        lightpostpartner:SetType("hermitcrab_lightpost")
        lightpostpartner:InitializeNumShackles(3)

        MakeSnowCoveredPristine(inst)

        if client_postinit then
            client_postinit(inst)
        end

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

        if name == "hermithouse_construction1" then
            inst.nolight = true
            inst.MiniMapEntity:SetIcon("hermitcrab_home.png")
        end

		if is_decoratable then
			inst:AddComponent("container")
			inst.components.container:WidgetSetup(name)
			inst:ListenForEvent("itemget", AddDecor)
			inst:ListenForEvent("itemlose", RemoveDecor)
			inst.RefreshDecor = RefreshDecor
			inst.ornamentfx = {}
		end

		local spawner = inst:AddComponent("spawner")
		spawner:Configure("hermitcrab", TUNING.TOTAL_DAY_TIME*1)
		spawner.onoccupied = onoccupied
		spawner.onvacate = onvacate
		spawner:SetWaterSpawning(false, true)
		spawner:CancelSpawning()

        if is_built_home then
            inst:AddComponent("pearldecorationscore")
            inst:ListenForEvent("ms_hermitcrab_relocated", function()
                if IsInValidHermitCrabDecorArea(inst) then
                    inst.components.pearldecorationscore:Enable()
                else
                    inst.components.pearldecorationscore:Disable()
                end
            end, TheWorld)
        end

		if house_data then
			inst._construction_product = house_data.construction_product

			local constructionsite = inst:AddComponent("constructionsite")
			constructionsite:SetConstructionPrefab("construction_container")
			constructionsite:SetOnConstructedFn(OnConstructed)
		end

		inst:SetPrefabNameOverride("hermithouse")

		local inspectable = inst:AddComponent("inspectable")
        inspectable.getstatus = getstatus

		inst.inittask = inst:DoTaskInTime(0, oninit)
        inst.dowind = dowind

        inst:ListenForEvent("clocksegschanged", function(world, data)
            inst.segs = data
            if inst.segs["night"] + inst.segs["dusk"] >= 16 then
                inst.components.spawner:ReleaseChild()
            end
        end, TheWorld)

		if inst.level >= 3 then
			inst:DoTaskInTime(math.random()*5, dowind)
        end

		inst.OnSave = onsave
		inst.OnLoad = onload

        MakeSnowCovered(inst)

        if master_postinit then
           master_postinit(inst)
        end

        TheWorld:PushEvent("ms_register_pearl_entity", inst)

        return inst
	end

	local _assets = assets
	if is_decoratable then
		_assets = shallowcopy(assets)
		table.insert(_assets, Asset("ANIM", "anim/ui_hermitcrab_2x2.zip"))
	end

	local _prefabs = prefabs
	if house_data then
		_prefabs = shallowcopy(prefabs)
		table.insert(_prefabs, "construction_container")
		table.insert(_prefabs, house_data.construction_product)
	elseif is_decoratable then
		_prefabs = shallowcopy(prefabs)
		table.insert(_prefabs, "hermithouse_ornament")
	end

	return Prefab(name, fn, _assets, _prefabs)
end

local ret = {}
for i = 1, #construction_data do
	table.insert(ret, MakeHermitCrabHouse(
        construction_data[i].name,
        construction_data[i].client_postinit,
        construction_data[i].master_postinit,
        construction_data[i]))
end
table.insert(ret, MakeHermitCrabHouse(
	construction_data[#construction_data].construction_product,
	nil,
	lvl5_master_postinit))

return unpack(ret)
