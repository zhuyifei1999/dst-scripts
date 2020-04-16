local assets =
{
    Asset("ANIM", "anim/reskin_tool.zip"),
    Asset("ANIM", "anim/swap_reskin_tool.zip"),
    Asset("ANIM", "anim/floating_items.zip"),
    Asset("ANIM", "anim/reskin_tool_fx.zip"),
}

local prefabs =
{
    "tornado",
}

local function spellCB(tool, target, pos)

    local fx = SpawnPrefab("explode_reskin")
    fx.Transform:SetPosition(target.Transform:GetWorldPosition())
    fx.scale_override = 1.7 * target:GetPhysicsRadius(0.5)
    print( "fx.scale_override", fx.scale_override )


    tool:DoTaskInTime(0, function()
        if target.skinname == tool._cached_reskinname[target.prefab] then
            local new_reskinname = nil
            local search_for_skin = tool._cached_reskinname[target.prefab] ~= nil
            if PREFAB_SKINS[target.prefab] ~= nil then
                for _,item_type in pairs(PREFAB_SKINS[target.prefab]) do
                    if search_for_skin then
                        if tool._cached_reskinname[target.prefab] == item_type then
                            search_for_skin = false
                        end
                    else
                        if TheInventory:CheckClientOwnership(tool.parent.userid, item_type) then
                            new_reskinname = item_type
                            break
                        end
                    end
                end
    
                tool._cached_reskinname[target.prefab] = new_reskinname
            end
        end
        
        TheSim:ReskinEntity( target.GUID, target.skinname, tool._cached_reskinname[target.prefab], nil, tool.parent.userid )
    end )
end

local function can_cast_fn(doer, target, pos)
    if PREFAB_SKINS[target.prefab] ~= nil then
        for _,item_type in pairs(PREFAB_SKINS[target.prefab]) do
            if TheInventory:CheckClientOwnership(doer.userid, item_type) then
                return true
            end
        end
    end

    --don't own any skins but check if we can go back to normal
    if target.skinname ~= nil then
        return true
    end

    return false
end


local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_reskin_tool", "swap_reskin_tool")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function tool_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("reskin_tool")
    inst.AnimState:SetBuild("reskin_tool")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("nopunch")

    --Sneak these into pristine state for optimization
    inst:AddTag("veryquickcast")

    --inst.spelltype = "SCIENCE"

    local swap_data = {sym_build = "swap_reskin_tool", bank = "reskin_tool"}
    MakeInventoryFloatable(inst, "med", 0.05, {1.0, 0.4, 1.0}, true, -20, swap_data)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("spellcaster")
    inst.components.spellcaster.canuseontargets = true
    inst.components.spellcaster.veryquickcast = true
    inst.components.spellcaster:SetSpellFn(spellCB)
    inst.components.spellcaster:SetCanCastFn(can_cast_fn)

    MakeHauntableLaunch(inst)

    inst._cached_reskinname = {}

    return inst
end

return Prefab("reskin_tool", tool_fn, assets, prefabs)