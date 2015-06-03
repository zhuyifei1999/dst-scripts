require "prefabutil"

local assets =
{
    Asset("ANIM", "anim/firepit.zip"),
}

local prefabs =
{
    "campfirefire",
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
    if inst.components.fueled ~= nil then
        inst.components.fueled:InitializeFuelLevel(0)
    end
end

local function ontakefuel(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/fireAddFuel")
end

local function onupdatefueled(inst)
    local fueled = inst.components.fueled
    local burnable = inst.components.burnable

    if TheWorld.state.israining then
        fueled.rate = 1 + TUNING.FIREPIT_RAIN_RATE * TheWorld.state.precipitationrate
    else
        fueled.rate = 1
    end
    
    if burnable ~= nil then
        burnable:SetFXLevel(fueled:GetCurrentSection(), fueled:GetSectionPercent())
    end
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

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle", false)
    inst.SoundEmitter:PlaySound("dontstarve/common/fireAddFuel")
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, .3)

    inst.MiniMapEntity:SetIcon("firepit.png")
    inst.MiniMapEntity:SetPriority(1)

    inst.AnimState:SetBank("firepit")
    inst.AnimState:SetBuild("firepit")
    inst.AnimState:PlayAnimation("idle", false)

    inst:AddTag("campfire")
    inst:AddTag("structure")
    inst:AddTag("wildfireprotected")

    --cooker (from cooker component) added to pristine state for optimization
    inst:AddTag("cooker")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -----------------------
    inst:AddComponent("burnable")
    --inst.components.burnable:SetFXLevel(2)
    inst.components.burnable:AddBurnFX("campfirefire", Vector3(0, .4, 0))
    inst:ListenForEvent("onextinguish", onextinguish)

    -------------------------
    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)    

    -------------------------
    inst:AddComponent("cooker")
    -------------------------
    inst:AddComponent("fueled")
    inst.components.fueled.maxfuel = TUNING.FIREPIT_FUEL_MAX
    inst.components.fueled.accepting = true

    inst.components.fueled:SetSections(4)
    inst.components.fueled.bonusmult = TUNING.FIREPIT_BONUS_MULT
    inst.components.fueled.ontakefuelfn = ontakefuel
    inst.components.fueled:SetUpdateFn(onupdatefueled)
    inst.components.fueled:SetSectionCallback( function(section)
        if section == 0 then
            inst.components.burnable:Extinguish() 
        else
            if not inst.components.burnable:IsBurning() then
                inst.components.burnable:Ignite()
            end

            inst.components.burnable:SetFXLevel(section, inst.components.fueled:GetSectionPercent())

        end
    end)
    inst.components.fueled:InitializeFuelLevel(TUNING.FIREPIT_FUEL_START)

    -----------------------------

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

    -----------------------------

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = getstatus

    inst:ListenForEvent("onbuilt", onbuilt)

    return inst
end

return Prefab("common/objects/firepit", fn, assets, prefabs),
    MakePlacer("common/firepit_placer", "firepit", "firepit", "preview")
