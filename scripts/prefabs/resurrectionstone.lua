local assets = 
{
	Asset("ANIM", "anim/resurrection_stone.zip"),
}

local prefabs =
{
	"rocks",
	"marble",
	"nightmarefuel",
}

local function OnActivate(inst)
	-- inst.components.resurrector.active = true
    ProfileStatsSet("resurrectionstone_activated", true)
	inst.AnimState:PlayAnimation("activate")
	inst.AnimState:PushAnimation("idle_activate", true)
	inst.SoundEmitter:PlaySound("dontstarve/common/resurrectionstone_activate")

	inst.AnimState:SetLayer(LAYER_WORLD)
	inst.AnimState:SetSortOrder(0)

	inst.Physics:CollidesWith(COLLISION.CHARACTERS)	
	inst.components.resurrector:OnBuilt()
end

local function makeactive(inst)
	inst.AnimState:PlayAnimation("idle_activate", true)
	inst.components.activatable.inactive = false
end

local function makeused(inst)
	inst.AnimState:PlayAnimation("idle_broken", true)
end

local function ondudewakeup()
    TheCamera:SetDefault()
    --SaveGameIndex:SaveCurrent(function() end)            
end

local function onresurrect(inst, dude)
    dude:Show()

    if dude and dude.components.burnable then
    	dude.components.burnable.burning = true
    end

    TheWorld:PushEvent("ms_sendlightningstrike", Vector3(inst.Transform:GetWorldPosition()))

    if dude and dude.components.burnable then 
    	dude.components.burnable.burning = false
    end

    inst.SoundEmitter:PlaySound("dontstarve/common/resurrectionstone_break")
    inst.components.lootdropper:DropLoot()
    inst:Remove()

    if dude.components.hunger then
        dude.components.hunger:SetPercent(2 / 3)
    end

    if dude.components.health then
        dude.components.health:Respawn(TUNING.RESURRECT_HEALTH)
    end

    if dude.components.sanity then
        dude.components.sanity:SetPercent(.5)
    end

    dude.components.hunger:Resume()

    dude.sg:GoToState("wakeup")

    dude:DoTaskInTime(3, ondudewakeup)
end

local function doresurrect(inst, dude)
	inst.isresurrecting = true
    inst.persists = false
	inst.MiniMapEntity:SetEnabled(false)
    if inst.Physics then
		MakeInventoryPhysics(inst) -- collides with world, but not character
    end
    ProfileStatsSet("resurrectionstone_used", true)

    TheWorld:PushEvent("ms_nextcycle")
    dude.Transform:SetPosition(inst.Transform:GetWorldPosition())
    dude:Hide()
    TheCamera:SetDistance(12)
	dude.components.hunger:Pause()
	
    scheduler:ExecuteInTime(3, onresurrect, nil, inst, dude)
end

local function OnHaunt(inst, haunter)
    inst.components.hauntable:SetOnHauntFn()

    inst.AnimState:PlayAnimation("activate")
    inst.AnimState:PushAnimation("idle_activate", true)
    inst.AnimState:SetLayer(LAYER_WORLD)
    inst.AnimState:SetSortOrder(0)

    inst.SoundEmitter:PlaySound("dontstarve/common/resurrectionstone_activate")

    inst.Physics:CollidesWith(COLLISION.CHARACTERS)

    return true
end

local function OnActivateResurrection(inst, guy)
    TheWorld:PushEvent("ms_sendlightningstrike", inst:GetPosition())
    inst.SoundEmitter:PlaySound("dontstarve/common/resurrectionstone_break")
    inst.components.lootdropper:DropLoot()
    inst:Remove()
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()

    if not GetGhostEnabled( TheNet:GetServerGameMode() ) then
        inst.entity:Hide()
        inst:DoTaskInTime(0, inst.Remove)
        return inst
    end

	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

	MakeObstaclePhysics(inst, 1)
	inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
	inst.Physics:ClearCollisionMask()
	inst.Physics:CollidesWith(COLLISION.WORLD)
	inst.Physics:CollidesWith(COLLISION.ITEMS)

    inst.AnimState:SetBank("resurrection_stone")
    inst.AnimState:SetBuild("resurrection_stone")
    inst.AnimState:PlayAnimation("idle_off")
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst.MiniMapEntity:SetIcon("resurrection_stone.png")

    inst:AddTag("resurrector")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetLoot({"rocks","rocks","marble","nightmarefuel","marble"})

	inst:AddComponent("resurrector")
	inst.components.resurrector.makeactivefn = makeactive
	inst.components.resurrector.makeusedfn = makeused
	inst.components.resurrector.doresurrect = doresurrect

	-- inst:AddComponent("activatable")
	-- inst.components.activatable.OnActivate = OnActivate
	-- inst.components.activatable.inactive = true
	inst:AddComponent("inspectable")
	inst.components.inspectable:RecordViews()

	inst:AddComponent("hauntable")
	inst.components.hauntable:SetHauntValue(TUNING.HAUNT_INSTANT_REZ)
    inst.components.hauntable:SetOnHauntFn(OnHaunt)

    inst:ListenForEvent("activateresurrection", OnActivateResurrection)

	return inst
end

return Prefab("forest/objects/resurrectionstone", fn, assets, prefabs)