local function OnStartBundling(inst)--, doer)
    inst.components.stackable:Get():Remove()
end

local function MakeWrap(name, containerprefab, tag, cheapfuel)
    local assets =
    {
        Asset("ANIM", "anim/"..name..".zip"),
    }

    local prefabs =
    {
        name,
        containerprefab,
    }

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank(name)
        inst.AnimState:SetBuild(name)
        inst.AnimState:PlayAnimation("idle")

        if tag ~= nil then
            inst:AddTag(tag)
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDITEM

        inst:AddComponent("inspectable")
        inst:AddComponent("inventoryitem")

        inst:AddComponent("bundlemaker")
        inst.components.bundlemaker:SetBundlingPrefabs(containerprefab, name)
        inst.components.bundlemaker:SetOnStartBundlingFn(OnStartBundling)

        inst:AddComponent("fuel")
        inst.components.fuel.fuelvalue = cheapfuel and TUNING.TINY_FUEL or TUNING.MED_FUEL

        MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
        MakeSmallPropagator(inst)
        inst.components.propagator.flashpoint = 10 + math.random() * 5
        MakeHauntableLaunchAndIgnite(inst)

        return inst
    end

    return Prefab(name.."wrap", fn, assets, prefabs)
end

local function MakeContainer(name, build)
    local assets =
    {
        Asset("ANIM", "anim/"..build..".zip"),
    }

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddNetwork()

        inst:AddTag("bundle")

        --V2C: blank string for controller action prompt
        inst.name = " "

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("container")
        inst.components.container:WidgetSetup(name)

        inst.persists = false

        return inst
    end

    return Prefab(name, fn, assets)
end

local function onburnt(inst)
    inst.burnt = true
    inst.components.unwrappable:Unwrap()
end

local function onignite(inst)
    inst.components.unwrappable.canbeunwrapped = false
end

local function onextinguish(inst)
    inst.components.unwrappable.canbeunwrapped = true
end

local function MakeBundle(name, onesize, variations, loot, tossloot)
    local assets =
    {
        Asset("ANIM", "anim/"..name..".zip"),
    }

    if variations ~= nil then
        for i = 1, variations do
            if onesize then
                table.insert(assets, Asset("INV_IMAGE", name..tostring(i)))
            else
                table.insert(assets, Asset("INV_IMAGE", name.."_small"..tostring(i)))
                table.insert(assets, Asset("INV_IMAGE", name.."_medium"..tostring(i)))
                table.insert(assets, Asset("INV_IMAGE", name.."_large"..tostring(i)))
            end
        end
    elseif not onesize then
        table.insert(assets, Asset("INV_IMAGE", name.."_small"))
        table.insert(assets, Asset("INV_IMAGE", name.."_medium"))
        table.insert(assets, Asset("INV_IMAGE", name.."_large"))
    end

    local prefabs =
    {
        "ash",
        name.."_unwrap",
    }

    if loot ~= nil then
        for i, v in ipairs(loot) do
            table.insert(prefabs, v)
        end
    end

    local function OnWrapped(inst, num, doer)
        local suffix =
            (onesize and "_onesize") or
            (num > 3 and "_large") or
            (num > 1 and "_medium") or
            "_small"

        if variations ~= nil then
            if inst.variation == nil then
                inst.variation = math.random(variations)
            end
            suffix = suffix..tostring(inst.variation)
            inst.components.inventoryitem:ChangeImageName(name..(onesize and tostring(inst.variation) or suffix))
        elseif not onesize then
            inst.components.inventoryitem:ChangeImageName(name..suffix)
        end

        inst.AnimState:PlayAnimation("idle"..suffix)

        if doer ~= nil and doer.SoundEmitter ~= nil then
            doer.SoundEmitter:PlaySound("dontstarve/common/together/packaged")
        end
    end

    local function OnUnwrapped(inst, pos, doer)
        if inst.burnt then
            SpawnPrefab("ash").Transform:SetPosition(pos:Get())
        else
            if loot ~= nil then
                for i, v in ipairs(loot) do
                    local item = SpawnPrefab(v)
                    if item ~= nil then
                        if item.Physics ~= nil then
                            item.Physics:Teleport(pos:Get())
                        else
                            item.Transform:SetPosition(pos:Get())
                        end
                        if tossloot and item.components.inventoryitem ~= nil then
                            item.components.inventoryitem:OnDropped(true, .5)
                        end
                    end
                end
            end
            SpawnPrefab(name.."_unwrap").Transform:SetPosition(pos:Get())
        end
        if doer ~= nil and doer.SoundEmitter ~= nil then
            doer.SoundEmitter:PlaySound("dontstarve/common/together/packaged")
        end
        inst:Remove()
    end

    local OnSave = variations ~= nil and function(inst, data)
        data.variation = inst.variation
    end or nil

    local OnPreLoad = variations ~= nil and function(inst, data)
        if data ~= nil then
            inst.variation = data.variation
        end
    end or nil

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank(name)
        inst.AnimState:SetBuild(name)
        inst.AnimState:PlayAnimation(
            variations ~= nil and
            (onesize and "idle_onesize1" or "idle_large1") or
            (onesize and "idle_onesize" or "idle_large")
        )

        inst:AddTag("bundle")

        --unwrappable (from unwrappable component) added to pristine state for optimization
        inst:AddTag("unwrappable")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")

        inst:AddComponent("inventoryitem")

        if variations ~= nil or not onesize then
            inst.components.inventoryitem:ChangeImageName(
                name..
                (variations == nil and "_large" or (onesize and "1" or "_large1"))
            )
        end

        inst:AddComponent("unwrappable")
        inst.components.unwrappable:SetOnWrappedFn(OnWrapped)
        inst.components.unwrappable:SetOnUnwrappedFn(OnUnwrapped)

        MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
        MakeSmallPropagator(inst)
        inst.components.propagator.flashpoint = 10 + math.random() * 5
        inst.components.burnable:SetOnBurntFn(onburnt)
        inst.components.burnable:SetOnIgniteFn(onignite)
        inst.components.burnable:SetOnExtinguishFn(onextinguish)

        MakeHauntableLaunchAndIgnite(inst)

        inst.OnSave = OnSave
        inst.OnPreLoad = OnPreLoad

        return inst
    end

    return Prefab(name, fn, assets, prefabs)
end

return MakeContainer("bundle_container", "ui_bundle_2x2"),
    --"bundle", "bundlewrap"
    MakeBundle("bundle", false, nil, { "waxpaper" }),
    MakeWrap("bundle", "bundle_container", nil, false),
    --"gift", "giftwrap"
    MakeBundle("gift", false, 2),
    MakeWrap("gift", "bundle_container", nil, true),
    --"redpouch"
    MakeBundle("redpouch", true, nil, { "lucky_goldnugget" }, true)
