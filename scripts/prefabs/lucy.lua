local assets =
{
    Asset("ANIM", "anim/lucy_axe.zip"),
    Asset("ANIM", "anim/swap_lucy_axe.zip"),
}

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_lucy_axe", "swap_lucy_axe")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function ondonetalking(inst)
    inst.SoundEmitter:KillSound("talk")
end

local function ontalk(inst)
    if inst.components.sentientaxe.sound_override ~= nil then
        inst.SoundEmitter:KillSound("talk")
        inst.SoundEmitter:PlaySound(inst.components.sentientaxe.sound_override, "special")
    elseif not inst.SoundEmitter:PlayingSound("special") then
        inst.SoundEmitter:PlaySound("dontstarve/characters/woodie/lucytalk_LP", "talk")
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.MiniMapEntity:SetIcon("lucy_axe.png")

    inst.AnimState:SetBank("Lucy_axe")
    inst.AnimState:SetBuild("Lucy_axe")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("sharp")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.AXE_DAMAGE*.5)

    -----
    inst:AddComponent("tool")
    inst.components.tool:SetAction(ACTIONS.CHOP, 2)

    -------

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("talker")
    inst:ListenForEvent("donetalking", ondonetalking)
    inst:ListenForEvent("ontalk", ontalk)

    inst.components.talker.fontsize = 28
    inst.components.talker.font = TALKINGFONT
    inst.components.talker.colour = Vector3(.9, .4, .4)
    inst.components.talker.offset = Vector3(0, 0, 0)
    inst.components.talker.symbol = "swap_object"

    inst:AddComponent("sentientaxe")

    MakeHauntableLaunch(inst)
    AddHauntableCustomReaction(inst, function(inst, haunter)
        if math.random() <= TUNING.HAUNT_CHANCE_ALWAYS then
            if inst.components.sentientaxe then
                inst.components.sentientaxe:MakeConversation()
                return true
            end
        end
        return false
    end, true, false, true)

    return inst
end

return Prefab("common/inventory/lucy", fn, assets)