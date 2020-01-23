local assets =
{
    Asset("ANIM", "anim/boat_mast2.zip"),
    Asset("INV_IMAGE", "mast_item"),
    Asset("ANIM", "anim/seafarer_mast.zip"),
}

local malbatross_assets =
{
    Asset("ANIM", "anim/boat_mast_malbatross.zip"), 
    Asset("ANIM", "anim/boat_mast_malbatross_knots.zip"), 
    Asset("ANIM", "anim/boat_mast_malbatross_opens.zip"), 
    Asset("ANIM", "anim/boat_mast_malbatross_build.zip"),
    Asset("ANIM", "anim/seafarer_mast_malbatross.zip"), -- item
}


local prefabs =
{
	"boat_mast_sink_fx",
	"collapse_small",
	"mast_item", -- deprecated but kept for existing worlds and mods
}

local malbatross_prefabs =
{
	"boat_malbatross_mast_sink_fx",
	"collapse_small",
	"mast_malbatross_item", -- deprecated but kept for existing worlds and mods
}

local function on_hammered(inst, hammerer)
    inst.components.lootdropper:DropLoot()

    local collapse_fx = SpawnPrefab("collapse_small")
    collapse_fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    collapse_fx:SetMaterial("wood")

    if inst.components.mast and hammerer ~= inst.components.mast.boat then
        inst.components.mast:SetBoat(nil)
    end
    inst:Remove()
end

local function on_hit(inst, hitter)
    if inst.components.mast and not inst.components.mast.is_sail_transitioning then
        if inst.components.mast.is_sail_raised ~= inst.components.mast.inverted then
            inst.AnimState:PlayAnimation("open2_hit")
            inst.AnimState:PushAnimation("open_loop",true)
        else
            inst.AnimState:PlayAnimation("closed_hit")
            inst.AnimState:PushAnimation("closed",true)
        end
    end
end

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("closed", false)
    inst.SoundEmitter:PlaySound("turnoftides/common/together/boat/mast/place")
end

local function onburnt(inst)
	inst:AddTag("burnt")

	local mast = inst.components.mast
	if mast.boat ~= nil then
		mast.boat.components.boatphysics:RemoveMast(mast)
	end

	inst:RemoveComponent("mast")
end

local function onsave(inst, data)
	if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() or inst:HasTag("burnt") then
		data.burnt = true
	end

	if inst.components.mast == nil or inst.components.mast.boat == nil then
		data.rotation = inst.Transform:GetRotation()
		data.is_sail_raised = inst.components.mast and inst.components.mast.is_sail_raised or nil
	end
end

local function onload(inst, data)
	if data ~= nil then
		if data.burnt then
			inst.components.burnable.onburnt(inst)
			inst:PushEvent("onburnt")
		end
		if data.rotation then
			inst.Transform:SetRotation(data.rotation)
		end
		if data.is_sail_raised and inst.components.mast ~= nil then
			inst.components.mast:SailUnfurled()
		end
	end
end

local function fn_pre(inst)
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    MakeObstaclePhysics(inst, .2)

    inst.Transform:SetEightFaced()

    inst:AddTag("NOBLOCK")
    inst:AddTag("structure")
    inst:AddTag("mast")
end

local function fn_pst(inst)
    MakeLargeBurnable(inst, nil, nil, true)
    inst:ListenForEvent("onburnt", onburnt)
    MakeLargePropagator(inst)

    inst:AddComponent("hauntable")
    inst:AddComponent("inspectable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    inst:AddComponent("mast")

    -- The loot that this drops is generated from the uncraftable recipe; see recipes.lua for the items.
    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(3)
    inst.components.workable:SetOnFinishCallback(on_hammered)
    inst.components.workable:SetOnWorkCallback(on_hit)
    
    inst:ListenForEvent("onbuilt", onbuilt)

    inst.OnSave = onsave
    inst.OnLoad = onload
end

local function fn()

    local inst = CreateEntity()

    fn_pre(inst)

    inst.AnimState:SetBank("mast_01")
    inst.AnimState:SetBuild("boat_mast2")
    inst.AnimState:PlayAnimation("closed")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    fn_pst(inst)

	if inst.components.mast ~= nil then
		inst.components.mast.sink_fx = "boat_mast_sink_fx"
	end

    return inst
end

local function malbatrossfn()

    local inst = CreateEntity()

    fn_pre(inst)

    inst.AnimState:SetBank("mast_malbatross")
    inst.AnimState:SetBuild("boat_mast_malbatross_build")
    inst.AnimState:PlayAnimation("closed")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    fn_pst(inst)

    inst.components.mast.sail_force = TUNING.BOAT.MAST.MALBATROSS.SAIL_FORCE
  --  inst.components.mast.max_velocity_mod = TUNING.BOAT.MAST.MALBATROSS.MAX_VELOCITY_MOD
    inst.components.mast.rudder_turn_drag = TUNING.BOAT.MAST.MALBATROSS.RUDDER_TURN_DRAG
    inst.components.mast.max_velocity = TUNING.BOAT.MAST.MALBATROSS.MAX_VELOCITY
    inst.components.mast:SetReveseDeploy(true)

	if inst.components.mast ~= nil then
		inst.components.mast.sink_fx = "boat_malbatross_mast_sink_fx"
	end

    return inst
end

local function setondeploy(inst, prefab)
    local function ondeploy(inst, pt, deployer, rot)
        local mast = SpawnPrefab( prefab, inst.linked_skinname, inst.skin_id )
        if mast ~= nil then
            mast.Physics:SetCollides(false)
            mast.Physics:Teleport(pt.x, 0, pt.z)
            mast.Physics:SetCollides(true)
            mast.SoundEmitter:PlaySound("turnoftides/common/together/boat/mast/place")
            mast.AnimState:PlayAnimation("place")
            mast.AnimState:PushAnimation("closed", false)
            if rot then
                mast.Transform:SetRotation(rot)
                mast.save_rotation = true
            end
            inst:Remove()
        end
    end

    inst.components.deployable.ondeploy = ondeploy  
end


local function item_fn_pre(inst)
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst:AddTag("boat_accessory")
    inst:AddTag("deploykititem")

    MakeInventoryPhysics(inst)

    MakeInventoryFloatable(inst, "med", 0.25, 0.83)
end

local function item_fn_pst(inst)
    inst:AddComponent("deployable")
    setondeploy(inst, "mast")
    inst.components.deployable:SetDeployMode(DEPLOYMODE.MAST)
    inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.LESS)   

    MakeLargeBurnable(inst)
    MakeLargePropagator(inst)

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")    

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.LARGE_FUEL

    MakeHauntableLaunch(inst)
end

local function item_fn()
    local inst = CreateEntity()

    item_fn_pre(inst)

    inst.AnimState:SetBank("seafarer_mast")
    inst.AnimState:SetBuild("seafarer_mast")
    inst.AnimState:PlayAnimation("IDLE")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    item_fn_pst(inst)

    return inst
end

local function malbatross_item_fn()
    local inst = CreateEntity()

    item_fn_pre(inst)

    inst.AnimState:SetBank("seafarer_mast_malbatross")
    inst.AnimState:SetBuild("seafarer_mast_malbatross")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    item_fn_pst(inst)
	
    setondeploy(inst ,"mast_malbatross")

    return inst
end

return Prefab("mast", fn, assets, prefabs),
       Prefab("mast_item", item_fn, assets),
       MakePlacer("mast_item_placer", "mast_01", "boat_mast2", "closed", nil,nil,nil,nil,0,"eight"),
       Prefab("mast_malbatross", malbatrossfn, malbatross_assets, malbatross_prefabs),
       Prefab("mast_malbatross_item", malbatross_item_fn, malbatross_assets),
       MakePlacer("mast_malbatross_item_placer", "mast_malbatross", "boat_mast_malbatross_build", "closed", nil,nil,nil,nil,0,"eight")
