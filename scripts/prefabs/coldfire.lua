require "prefabutil"

local assets =
{
    Asset("ANIM", "anim/coldfire.zip"),
}

local prefabs =
{
    "coldfirefire",
    "collapse_small",
}

local function onhammered(inst, worker)
    local x, y, z = inst.Transform:GetWorldPosition()
    inst.components.lootdropper:DropLoot()
    SpawnPrefab("ash").Transform:SetPosition(x, y, z)
    SpawnPrefab("collapse_small").Transform:SetPosition(x, y, z)
    inst:Remove()
end

local function onextinguish(inst)
    if inst.components.fueled ~= nil then
        inst.components.fueled:InitializeFuelLevel(0)
    end
end

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle_loop", false)
    inst.SoundEmitter:PlaySound("dontstarve/common/fireAddFuel")
end

local SECTION_STATUS =
{
    [0] = "OUT",
    [1] = "EMBERS",
    [2] = "LOW",
    [3] = "NORMAL",
    [4] = "HIGH",
}
local function getstatus(inst)
    return SECTION_STATUS[inst.components.fueled:GetCurrentSection()]
end

local function OnHaunt(inst)
    if inst.components.fueled ~= nil and math.random() <= TUNING.HAUNT_CHANCE_OCCASIONAL then
        inst.components.fueled:DoDelta(TUNING.TINY_FUEL)
        return true
    end
    return false
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.MiniMapEntity:SetIcon("coldfire.png")
    inst.MiniMapEntity:SetPriority(1)

    inst.AnimState:SetBank("coldfire")
    inst.AnimState:SetBuild("coldfire")
    inst.AnimState:PlayAnimation("idle_loop", false)

    inst:AddTag("campfire")
    inst:AddTag("structure")

    MakeObstaclePhysics(inst, .3)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -----------------------
    inst:AddComponent("burnable")
    --inst.components.burnable:SetFXLevel(2)
    inst.components.burnable:AddBurnFX("coldfirefire", Vector3(0, 0, 0))
    inst:ListenForEvent("onextinguish", onextinguish)

    -------------------------
    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)

    -------------------------
    inst:AddComponent("fueled")
    inst.components.fueled.maxfuel = TUNING.COLDFIRE_FUEL_MAX
    inst.components.fueled.secondaryfueltype = FUELTYPE.CHEMICAL
    inst.components.fueled.accepting = true    
    inst.components.fueled:SetSections(4)
    inst.components.fueled.ontakefuelfn = function() inst.SoundEmitter:PlaySound("dontstarve/common/fireAddFuel") end

    inst.components.fueled:SetUpdateFn(function()
        if TheWorld.state.israining then
            inst.components.fueled.rate = 1 + TUNING.COLDFIRE_RAIN_RATE * TheWorld.state.precipitationrate
        else
            inst.components.fueled.rate = 1
        end

        if inst.components.burnable ~= nil and inst.components.fueled ~= nil then
            inst.components.burnable:SetFXLevel(inst.components.fueled:GetCurrentSection(), inst.components.fueled:GetSectionPercent())
        end
    end)

    inst.components.fueled:SetSectionCallback(
        function(section)
            if section == 0 then
                inst.components.burnable:Extinguish() 
                inst.AnimState:PlayAnimation("dead") 
                RemovePhysicsColliders(inst)             
                SpawnPrefab("ash").Transform:SetPosition(inst.Transform:GetWorldPosition())
                -- if math.random() < .5 then
                --     local gold = SpawnPrefab("goldnugget")
                --     gold.Transform:SetPosition(inst.Transform:GetWorldPosition())
                -- end
                inst.components.fueled.accepting = false
                inst.persists = false
                inst:DoTaskInTime(1, ErodeAway)
            else
                if not inst.components.burnable:IsBurning() then
                    inst.components.burnable:Ignite()
                end
                inst.AnimState:PlayAnimation("idle_loop") 
                inst.components.burnable:SetFXLevel(section, inst.components.fueled:GetSectionPercent() )
                inst.components.fueled.rate = 1
            end
        end)

    inst.components.fueled:InitializeFuelLevel(TUNING.COLDFIRE_FUEL_START)

    -----------------------------

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = getstatus

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_SMALL)
    inst.components.hauntable.cooldown = TUNING.HAUNT_COOLDOWN_HUGE
    inst.components.hauntable:SetOnHauntFn(OnHaunt)

    inst:ListenForEvent("onbuilt", onbuilt)

    return inst
end

return Prefab("coldfire", fn, assets, prefabs),
    MakePlacer("coldfire_placer", "coldfire", "coldfire", "preview")
