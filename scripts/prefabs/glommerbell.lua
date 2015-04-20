local assets =
{
    Asset("anim", "anim/bell.zip"),
}

local function OnPlayed(inst, musician)
    if TheWorld.components.bigfooter then
        TheWorld.components.bigfooter:SummonFoot(musician:GetPosition())
    end
end

local function shine(inst)
    inst.task = nil
    inst.AnimState:PlayAnimation("sparkle")
    inst.AnimState:PushAnimation("idle")
    inst.task = inst:DoTaskInTime(4 + math.random() * 5, shine)
end

local function OnPutInInv(inst, owner)
    if owner.prefab == "mole" or owner.prefab == "krampus" then
        inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/glommer_bell")
        OnPlayed(inst, owner)
        if inst.components.finiteuses then inst.components.finiteuses:Use() end
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("bell")
    inst.AnimState:SetBuild("bell")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("bell")
    inst:AddTag("molebait")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")

    inst:ListenForEvent( "onstolen", function(inst, data)
        if data.thief.components.inventory then
            data.thief.components.inventory:GiveItem(inst)
        end
    end)
    inst.components.inventoryitem:SetOnPutInInventoryFn(OnPutInInv)

    inst:AddComponent("instrument")
    inst.components.instrument.onplayed = OnPlayed

    inst:AddComponent("tool")
    inst.components.tool:SetAction(ACTIONS.PLAY)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(TUNING.GLOMMERBELL_USES)
    inst.components.finiteuses:SetUses(TUNING.GLOMMERBELL_USES)
    inst.components.finiteuses:SetOnFinished(inst.Remove)
    inst.components.finiteuses:SetConsumption(ACTIONS.PLAY, 1)
    shine(inst)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("bell", fn, assets)