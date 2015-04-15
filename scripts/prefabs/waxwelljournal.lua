local assets =
{
	Asset("ANIM", "anim/book_maxwell.zip"),
}

local prefabs =
{
	"shadowwaxwell",
    "waxwell_book_fx"
}

local function doeffects(inst, pos)
    SpawnPrefab("statue_transition").Transform:SetPosition(pos:Get())
    SpawnPrefab("statue_transition_2").Transform:SetPosition(pos:Get())
end

local function canread(inst)
    return inst.components.sanity:GetMaxWithPenalty() >= TUNING.SHADOWWAXWELL_SANITY_PENALTY
end

local function onread(inst, reader, ignorecosts)

    --Check sanity
    if not ignorecosts and not canread(reader) then 
        if reader.components.talker then
            reader.components.talker:Say(GetString(reader.prefab, "ANNOUNCE_NOSANITY"))
            return true
        end
    end

    --Check reagent
    if not ignorecosts and not reader.components.inventory:Has("nightmarefuel", TUNING.SHADOWWAXWELL_FUEL_COST) then
        if reader.components.talker then
            reader.components.talker:Say(GetString(reader.prefab, "ANNOUNCE_NOFUEL"))
            return true
        end
    end

    if not ignorecosts then
        reader.components.inventory:ConsumeByName("nightmarefuel", TUNING.SHADOWWAXWELL_FUEL_COST)
    end

    --Ok you had everything. Make the image.
    local theta = math.random() * 2 * PI
    local pt = inst:GetPosition()
    local radius = math.random(3, 6)
    local offset = FindWalkableOffset(pt, theta, radius, 12, true)
    if offset then
        local image = SpawnPrefab("shadowwaxwell")
        local pos = pt + offset
        image.Transform:SetPosition(pos:Get())
        doeffects(inst, pos)
        image.components.follower:SetLeader(reader)
        if not ignorecosts then reader.components.health:DoDelta(-TUNING.SHADOWWAXWELL_HEALTH_COST) end
        if not ignorecosts then reader.components.sanity:RecalculatePenalty() end
        inst.SoundEmitter:PlaySound("dontstarve/maxwell/shadowmax_appear")
        return true
    end
end



local function fn()
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
    local sound = inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    if not TheWorld.ismastersim then
        return inst
    end
    
    anim:SetBank("book_maxwell")
    anim:SetBuild("book_maxwell")
    anim:PlayAnimation("idle")
    
    inst:AddComponent("inventoryitem")

    -----------------------------------
    inst:AddComponent("inspectable")
    inst:AddComponent("book")
    inst.components.book.onread = onread

    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)

    -- inst:AddComponent("characterspecific")
    -- inst.components.characterspecific:SetOwner("waxwell")

    MakeHauntableLaunch(inst)
    AddHauntableCustomReaction(inst, function(inst, haunter)
        if math.random() <= TUNING.HAUNT_CHANCE_OCCASIONAL then
            inst.components.book.onread(inst, haunter, true)
            inst.components.hauntable.hauntvalue = TUNING.HAUNT_MEDIUM
            return true
        end
        return false
    end, true, false, true)


    return inst
end

return Prefab("common/waxwelljournal", fn, assets)