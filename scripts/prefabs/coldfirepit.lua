require "prefabutil"

local assets =
{
    Asset("ANIM", "anim/coldfirepit.zip"),
}

local prefabs =
{
    "coldfirefire",
    "collapse_small",
}

local function onhammered(inst, worker)
    inst.components.lootdropper:DropLoot()
    local ash = SpawnPrefab("ash")
    ash.Transform:SetPosition(inst.Transform:GetWorldPosition())
    SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_stone")
    inst:Remove()
end

local function onhit(inst, worker)
    inst.AnimState:PlayAnimation("hit")
    inst.AnimState:PushAnimation("idle")
end

local function onextinguish(inst)
    if inst.components.fueled then
        inst.components.fueled:InitializeFuelLevel(0)
    end
end

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle", false)
    inst.SoundEmitter:PlaySound("dontstarve/common/fireAddFuel")
end

local function getstatus(inst)
    local sec = inst.components.fueled:GetCurrentSection()
    if sec == 0 then 
        return "OUT"
    elseif sec <= 4 then
        local t = {"EMBERS","LOW","NORMAL","HIGH"}
        return t[sec]
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.MiniMapEntity:SetIcon("coldfirepit.png")
    inst.MiniMapEntity:SetPriority(1)

    inst.AnimState:SetBank("coldfirepit")
    inst.AnimState:SetBuild("coldfirepit")
    inst.AnimState:PlayAnimation("idle", false)

    inst:AddTag("campfire")
    inst:AddTag("structure")
    inst:AddTag("wildfireprotected")

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
    inst.components.workable:SetOnWorkCallback(onhit)

    -------------------------
    inst:AddComponent("fueled")
    inst.components.fueled.maxfuel = TUNING.COLDFIREPIT_FUEL_MAX
    inst.components.fueled.accepting = true
    inst.components.fueled.secondaryfueltype = FUELTYPE.CHEMICAL
    inst.components.fueled:SetSections(4)
    inst.components.fueled.bonusmult = TUNING.COLDFIREPIT_BONUS_MULT
    inst.components.fueled.ontakefuelfn = function() inst.SoundEmitter:PlaySound("dontstarve/common/fireAddFuel") end

    inst.components.fueled:SetUpdateFn(function()
        if TheWorld.state.israining then
            inst.components.fueled.rate = 1 + TUNING.COLDFIREPIT_RAIN_RATE*TheWorld.state.precipitationrate
        else
            inst.components.fueled.rate = 1
        end

        if inst.components.burnable and inst.components.fueled then
            inst.components.burnable:SetFXLevel(inst.components.fueled:GetCurrentSection(), inst.components.fueled:GetSectionPercent())
        end
    end)

    inst.components.fueled:SetSectionCallback(function(section)
        if section == 0 then
            inst.components.burnable:Extinguish() 
        else
            if not inst.components.burnable:IsBurning() then
                inst.components.burnable:Ignite()
            end
            inst.components.burnable:SetFXLevel(section, inst.components.fueled:GetSectionPercent())
        end
    end)

    inst.components.fueled:InitializeFuelLevel(TUNING.COLDFIREPIT_FUEL_START)

    -----------------------------

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = getstatus

    inst:AddComponent("hauntable")
    inst.components.hauntable.cooldown = TUNING.HAUNT_COOLDOWN_HUGE
    inst.components.hauntable:SetOnHauntFn(function(inst, haunter)
        local ret = false
        if math.random() <= TUNING.HAUNT_CHANCE_RARE then
            if inst.components.fueled and not inst.components.fueled:IsEmpty() then
                inst.components.fueled:DoDelta(TUNING.MED_FUEL)
                inst.components.hauntable.hauntvalue = TUNING.HAUNT_SMALL
                ret = true
            end
        end
        if math.random() <= TUNING.HAUNT_CHANCE_HALF then
            if inst.components.workable and inst.components.workable.workleft > 0 then
                inst.components.workable:WorkedBy(haunter, 1)
                inst.components.hauntable.hauntvalue = TUNING.HAUNT_SMALL
                ret = true
            end
        end
        return ret
    end)

    inst:ListenForEvent("onbuilt", onbuilt)

    return inst
end

return Prefab("common/objects/coldfirepit", fn, assets, prefabs),
MakePlacer("common/coldfirepit_placer", "coldfirepit", "coldfirepit", "preview")