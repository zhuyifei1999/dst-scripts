local function makeassetlist(bankname, buildname)
    return {
        Asset("ANIM", "anim/"..buildname..".zip"),
        Asset("ANIM", "anim/"..bankname..".zip"),
    }
end

local function makefn(bankname, buildname, animname)
    return function()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        inst:AddTag("DECOR")

        inst.AnimState:SetBank(bankname)
        inst.AnimState:SetBuild(buildname)
        inst.AnimState:PlayAnimation(animname)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        return inst
    end
end

local function item(name, bankname, buildname, animname)
    return Prefab(name, makefn(bankname, buildname, animname), makeassetlist(bankname, buildname))
end

return item("farmrock", "farm_decor", "farm_decor", "1"),
        item("farmrocktall", "farm_decor", "farm_decor", "2"),
        item("farmrockflat", "farm_decor", "farm_decor", "8"),
        item("stick", "farm_decor", "farm_decor", "3"),
        item("stickright", "farm_decor", "farm_decor", "6"),
        item("stickleft", "farm_decor", "farm_decor", "7"),
        item("signleft", "farm_decor", "farm_decor", "4"),
        item("fencepost", "farm_decor", "farm_decor", "5"),
        item("fencepostright", "farm_decor", "farm_decor", "9"),
        item("signright", "farm_decor", "farm_decor", "10"),
        item("burntstickleft", "farm_decor", "farm_decor", "11"),
        item("burntstick", "farm_decor", "farm_decor", "12"),
        item("burntfencepostright", "farm_decor", "farm_decor", "13"),
        item("burntfencepost", "farm_decor", "farm_decor", "14"),
        item("burntstickright", "farm_decor", "farm_decor", "15")