local assets =
{
    Asset("ANIM", "anim/meteor.zip"),
    Asset("ANIM", "anim/warning_shadow.zip"),
    Asset("ANIM", "anim/meteor_shadow.zip"),
}

local prefabs =
{
    "meteorwarning",
    "burntground",
    "splash_ocean",
    "rock_moon",
}

local function onexplode(inst)

    inst.SoundEmitter:PlaySound("dontstarve/common/meteor_impact")

    if inst.warnshadow then
        inst.warnshadow:Remove()
    end

    local shakeduration = .7 * inst.size
    local shakespeed = .02 * inst.size
    local shakescale = .5 * inst.size
    local shakemaxdist = 40 * inst.size
    for i, v in ipairs(AllPlayers) do
        v:ShakeCamera(CAMERASHAKE.FULL, shakeduration, shakespeed, shakescale, inst, shakemaxdist)
    end

    local x, y, z = inst.Transform:GetWorldPosition()

    if not inst:IsOnValidGround() then
        local splash = SpawnPrefab("splash_ocean")
        if splash then
            splash.Transform:SetPosition(x, y, z)
        end
    else
        local scorch = SpawnPrefab("burntground")
        if scorch then
            scorch.Transform:SetPosition(x, y, z)
            local scale = inst.size * 1.3
            scorch.Transform:SetScale(scale, scale, scale)
        end

    	local ents = TheSim:FindEntities(x, y, z, inst.size * TUNING.METEOR_RADIUS, nil, { "INLIMBO" })
        for k,v in pairs(ents) do
            --V2C: things "could" go invalid if something earlier in the list
            --     removes something later in the list.
            --     another problem is containers, occupiables, traps, etc.
            --     inconsistent behaviour with what happens to their contents
            --     also, stuff in backpacks will just get removed, even if they
            --     shouldn't (like eyebones)
            if v:IsValid() and
                not (v.components.inventoryitem ~= nil and
                    v.components.inventoryitem:IsHeld()) then

                if v.components.workable and not v:HasTag("busy") then
                    v.components.workable:WorkedBy(inst, inst.workdone or 20)
                end

                if v.components.combat and not v:HasTag("playerghost") then
                    v.components.combat:GetAttacked(inst, inst.size*TUNING.METEOR_DAMAGE, nil)
                end

                if v.components.inventoryitem then
                    if math.random() <= TUNING.METEOR_SMASH_INVITEM_CHANCE then
                        inst.SoundEmitter:PlaySound("dontstarve/common/stone_drop")
                        local x1, y1, z1 = v.Transform:GetWorldPosition()
                        local breaking = SpawnPrefab("ground_chunks_breaking") --spawn break effect
                        breaking.Transform:SetPosition(x1, 0, z1)
                        v:Remove()
                    else
                        Launch(v, inst, TUNING.LAUNCH_SPEED_SMALL)
                    end
                end
            end
        end

        for i,v in pairs(inst.loot) do
            if math.random() <= v.chance then
                local drop = SpawnPrefab(v.prefab)
                if drop then
                    drop.Transform:SetPosition(x, y, z)
                    if drop.components.inventoryitem then
                        drop.components.inventoryitem:OnDropped(true)
                    end
                end
            end
        end
    end
end

local function dostrike(inst)
    inst.striketask = nil
    inst.AnimState:PlayAnimation("crash")
    inst:DoTaskInTime(0.33, onexplode)
    inst:ListenForEvent("animover", inst.Remove)
    -- animover isn't triggered when the entity is asleep, so just in case
    local len = inst.AnimState:GetCurrentAnimationLength()
    inst:DoTaskInTime(len + 0.1,inst.Remove)
end

local warntime = 1
local sizes = 
{ 
    small = .7, 
    medium = 1, 
    large = 1.3,
}
local work =
{
    small = 1, 
    medium = 2, 
    large = 20,   
}

local function SetSize(inst, sz, mod)
    if inst.striketask ~= nil then
        return
    end

    if sizes[sz] == nil then
        sz = "small"
    end

    inst.size = sizes[sz]
    inst.workdone = work[sz]
    inst.warnshadow = SpawnPrefab("meteorwarning")

    if mod == nil then
        mod = 1
    end

    local rand = math.random()
    inst.loot = {}
    if sz == "small" then
        -- No loot
    elseif sz == "medium" then
        table.insert(inst.loot, {prefab='rocks', chance=TUNING.METEOR_CHANCE_INVITEM_OFTEN*mod})
        table.insert(inst.loot, {prefab='rocks', chance=TUNING.METEOR_CHANCE_INVITEM_RARE*mod})
        table.insert(inst.loot, {prefab='flint', chance=TUNING.METEOR_CHANCE_INVITEM_ALWAYS*mod})
        table.insert(inst.loot, {prefab='flint', chance=TUNING.METEOR_CHANCE_INVITEM_VERYRARE*mod})
        table.insert(inst.loot, {prefab='moonrocknugget', chance=TUNING.METEOR_CHANCE_INVITEM_SUPERRARE*mod})
    elseif sz == "large" then
        local picked_boulder = false
        if rand <= TUNING.METEOR_CHANCE_BOULDERMOON*mod then
            table.insert(inst.loot, {prefab="rock_moon", chance=1})
            picked_boulder = true
        end
        if not picked_boulder and rand <= TUNING.METEOR_CHANCE_BOULDERFLINTLESS*mod then
            local r = math.random()
            if r <= .33 then -- Randomize which flintless rock we use
                table.insert(inst.loot, {prefab="rock_flintless", chance=1})
            elseif r <= .67 then
                table.insert(inst.loot, {prefab="rock_flintless_med", chance=1})
            else
                table.insert(inst.loot, {prefab="rock_flintless_low", chance=1})
            end
            picked_boulder = true
        end
        if not picked_boulder then -- Don't check for chance or mod this one: we need to pick a boulder
            table.insert(inst.loot, {prefab="rock1", chance=1})
        end
    end

    inst.Transform:SetScale(inst.size,inst.size,inst.size)
    inst.warnshadow.Transform:SetScale(inst.size,inst.size,inst.size)

    -- Now that we've been set to the appropriate size, go for the gusto
    inst.striketask = inst:DoTaskInTime(warntime, dostrike)

    inst.warnshadow.entity:SetParent(inst.entity)
    inst.warnshadow.startfn(inst.warnshadow, warntime, .33, 1)
end

local function AutoSize(inst)
    if inst.striketask == nil then
        local rand = math.random()
        SetSize(inst, rand <= .33 and "large" or (rand <= .67 and "medium" or "small"))
    end
end

local function fn() 
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    
    inst.Transform:SetTwoFaced()

	inst.AnimState:SetBank("meteor")
	inst.AnimState:SetBuild("meteor")

    inst:AddTag("NOCLICK")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()

    inst.Transform:SetRotation(math.random(1, 360))
    inst.SetSize = SetSize
    inst.striketask = nil

    -- For spawning these things in ways other than from meteor showers (failsafe set a size after .5s)
    inst:DoTaskInTime(.5, AutoSize)

    inst.persists = false

	return inst
end

return Prefab("common/shadowmeteor", fn, assets, prefabs)