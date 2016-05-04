local function ontransplantfn(inst)
    inst.components.pickable:MakeBarren()
end

local function ondiseaseddeathfn(inst)
    SpawnPrefab("disease_puff").Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst:Remove()
end

local function onrebirthedfn(inst)
    if inst.components.pickable:CanBePicked() then
        inst.components.pickable:MakeEmpty()
    end
end

local function ondiseasedfn_common(inst, diseasefx)
    SpawnPrefab(diseasefx).Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst.AnimState:SetBuild(inst.prefab.."_diseased_build")
    inst.components.pickable:ChangeProduct("spoiled_food")
end

local function ondiseasedfn_normal(inst)
    ondiseasedfn_common(inst, "disease_fx_small")
end

local function ondiseasedfn_juicy(inst)
    ondiseasedfn_common(inst, inst.components.witherable ~= nil and inst.components.witherable:IsWithered() and "disease_fx_small" or "disease_fx")
end

local function makeemptyfn(inst)
    if not POPULATING and inst:HasTag("withered") or inst.AnimState:IsCurrentAnimation("idle_dead") then
        --inst.SoundEmitter:PlaySound("dontstarve/common/bush_fertilize")
        inst.AnimState:PlayAnimation("dead_to_empty")
        inst.AnimState:PushAnimation("empty", false)
    else
        inst.AnimState:PlayAnimation("empty")
    end
end

local function makebarrenfn(inst, wasempty)
    if not POPULATING and inst:HasTag("withered") then
        inst.AnimState:PlayAnimation(wasempty and "empty_to_dead" or "full_to_dead")
        inst.AnimState:PushAnimation("idle_dead", false)
    else
        inst.AnimState:PlayAnimation("idle_dead")
    end
end

local function pickanim(inst)
    if inst.components.pickable == nil then
        return "idle"
    elseif not inst.components.pickable:CanBePicked() then
        return inst.components.pickable:IsBarren() and "idle_dead" or "idle"
    end

    --V2C: nil cycles_left means unlimited picks, so use max value for math
    local percent = inst.components.pickable.cycles_left ~= nil and inst.components.pickable.cycles_left / inst.components.pickable.max_cycles or 1
    return (percent >= .9 and "berriesmost")
        or (percent >= .33 and "berriesmore")
        or "berries"
end

local function shake(inst)
    inst.AnimState:PlayAnimation(
        inst.components.pickable ~= nil and
        inst.components.pickable:CanBePicked() and
        "shake" or
        "shake_empty")
    inst.AnimState:PushAnimation(pickanim(inst), false)
end

local function spawnperd(inst)
    if inst:IsValid() then
        local perd = SpawnPrefab("perd")
        local x, y, z = inst.Transform:GetWorldPosition()
        local angle = math.random() * 2 * PI
        perd.Transform:SetPosition(x + math.cos(angle), 0, z + math.sin(angle))
        perd.sg:GoToState("appear")
        perd.components.homeseeker:SetHome(inst)
        shake(inst)
    end
end

local function onpickedfn(inst, picker)
    if inst.components.pickable ~= nil then
        --V2C: nil cycles_left means unlimited picks, so use max value for math
        local old_percent = inst.components.pickable.cycles_left ~= nil and (inst.components.pickable.cycles_left + 1) / inst.components.pickable.max_cycles or 1
        inst.AnimState:PlayAnimation(
            (old_percent >= .9 and "berriesmost_picked") or
            (old_percent >= .33 and "berriesmore_picked") or
            "berries_picked")
        inst.AnimState:PushAnimation(
            inst.components.pickable:IsBarren() and
            "idle_dead" or
            "idle",
            false)
    end
    if not picker:HasTag("berrythief") and math.random() < TUNING.PERD_SPAWNCHANCE then
        inst:DoTaskInTime(3 + math.random() * 3, spawnperd)
    end
end

local function getregentimefn_normal(inst)
    if inst.components.pickable == nil then
        return TUNING.BERRY_REGROW_TIME
    end
    --V2C: nil cycles_left means unlimited picks, so use max value for math
    local max_cycles = inst.components.pickable.max_cycles
    local cycles_left = inst.components.pickable.cycles_left or max_cycles
    local num_cycles_passed = math.max(0, max_cycles - cycles_left)
    return TUNING.BERRY_REGROW_TIME
        + TUNING.BERRY_REGROW_INCREASE * num_cycles_passed
        + TUNING.BERRY_REGROW_VARIANCE * math.random()
end

local function getregentimefn_juicy(inst)
    if inst.components.pickable == nil then
        return TUNING.BERRY_JUICY_REGROW_TIME
    end
    --V2C: nil cycles_left means unlimited picks, so use max value for math
    local max_cycles = inst.components.pickable.max_cycles
    local cycles_left = inst.components.pickable.cycles_left or max_cycles
    local num_cycles_passed = math.max(0, max_cycles - cycles_left)
    return TUNING.BERRY_JUICY_REGROW_TIME
        + TUNING.BERRY_JUICY_REGROW_INCREASE * num_cycles_passed
        + TUNING.BERRY_JUICY_REGROW_VARIANCE * math.random()
end

local function makefullfn(inst)
    inst.AnimState:PlayAnimation(pickanim(inst))
end

local function onworked_juicy(inst, worker, workleft)
    --This is possible when beaver is gnaw-digging the bush,
    --and the expected behaviour should be same as jostling.
    if workleft > 0 and
        inst.components.lootdropper ~= nil and
        inst.components.pickable ~= nil and
        inst.components.pickable.droppicked and
        inst.components.pickable:CanBePicked() then
        inst.components.pickable:Pick(worker)
    end
end

local function dig_up_common(inst, numberries)
    if inst.components.pickable ~= nil and inst.components.lootdropper ~= nil then
        if inst.components.pickable:IsBarren() or inst:HasTag("withered") then
            inst.components.lootdropper:SpawnLootPrefab("twigs")
            inst.components.lootdropper:SpawnLootPrefab("twigs")
        else
            if inst.components.pickable:CanBePicked() then
                local pt = inst:GetPosition()
                pt.y = pt.y + (inst.components.pickable.dropheight or 0)
                for i = 1, numberries do
                    inst.components.lootdropper:SpawnLootPrefab(inst.components.pickable.product, pt)
                end
            end
            inst.components.lootdropper:SpawnLootPrefab("dug_"..inst.prefab)
        end
    end
    inst:Remove()
end

local function dig_up_normal(inst)
    dig_up_common(inst, 1)
end

local function dig_up_juicy(inst)
    dig_up_common(inst, 3)
end

local function OnHaunt(inst)
    if math.random() <= TUNING.HAUNT_CHANCE_ALWAYS then
        shake(inst)
        inst.components.hauntable.hauntvalue = TUNING.HAUNT_COOLDOWN_TINY
        return true
    end
    return false
end

local function createbush(bushname, bank, build, berryname, diseaseable, master_postinit)
    local assets =
    {
        Asset("ANIM", "anim/"..bank..".zip"),
    }
    if bank ~= build then
        table.insert(assets, Asset("ANIM", "anim/"..build..".zip"))
    end

    local prefabs =
    {
        berryname,
        "dug_"..bushname,
        "perd",
        "twigs",
    }

    if diseaseable then
        table.insert(assets, Asset("ANIM", "anim/"..bushname.."_diseased_build.zip"))
        table.insert(prefabs, "disease_puff")
        table.insert(prefabs, "disease_fx_small")
        table.insert(prefabs, "disease_fx")
        table.insert(prefabs, "diseaseflies")
    end

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()

        MakeSmallObstaclePhysics(inst, .1)

        inst:AddTag("bush")
        inst:AddTag("renewable")

        --witherable (from witherable component) added to pristine state for optimization
        inst:AddTag("witherable")

        inst.MiniMapEntity:SetIcon(bushname..".png")

        inst.AnimState:SetBank(bank)
        inst.AnimState:SetBuild(build)
        inst.AnimState:PlayAnimation("berriesmost", false)

        MakeDragonflyBait(inst, 1)
        MakeSnowCoveredPristine(inst)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("pickable")
        inst.components.pickable.picksound = "dontstarve/wilson/harvest_berries"
        inst.components.pickable.onpickedfn = onpickedfn
        inst.components.pickable.makeemptyfn = makeemptyfn
        inst.components.pickable.makebarrenfn = makebarrenfn
        inst.components.pickable.makefullfn = makefullfn
        inst.components.pickable.ontransplantfn = ontransplantfn

        inst:AddComponent("witherable")

        MakeLargeBurnable(inst)
        MakeMediumPropagator(inst)

        MakeHauntableIgnite(inst)
        AddHauntableCustomReaction(inst, OnHaunt, false, false, true)

        if diseaseable then
            inst:AddComponent("diseaseable")
            inst.components.diseaseable:SetRebirthedFn(onrebirthedfn)
            inst.components.diseaseable:SetDiseasedDeathFn(ondiseaseddeathfn)
        end

        inst:AddComponent("lootdropper")
        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.DIG)
        inst.components.workable:SetWorkLeft(1)

        inst:AddComponent("inspectable")
        inst.components.inspectable.nameoverride = "berrybush"

        inst:ListenForEvent("onwenthome", shake)
        MakeSnowCovered(inst)
        MakeNoGrowInWinter(inst)

        master_postinit(inst)

        return inst
    end

    return Prefab(bushname, fn, assets, prefabs)
end

local function normal_postinit(inst)
    inst.components.pickable:SetUp("berries", TUNING.BERRY_REGROW_TIME)
    inst.components.pickable.getregentimefn = getregentimefn_normal
    inst.components.pickable.max_cycles = TUNING.BERRYBUSH_CYCLES + math.random(2)
    inst.components.pickable.cycles_left = inst.components.pickable.max_cycles

    if inst.components.diseaseable ~= nil then
        inst.components.diseaseable:SetDiseasedFn(ondiseasedfn_normal)
    end

    inst.components.workable:SetOnFinishCallback(dig_up_normal)
end

local function juicy_postinit(inst)
    inst.components.pickable:SetUp("berries_juicy", TUNING.BERRY_JUICY_REGROW_TIME, 3)
    inst.components.pickable.getregentimefn = getregentimefn_juicy
    inst.components.pickable.max_cycles = TUNING.BERRYBUSH_JUICY_CYCLES + math.random(2)
    inst.components.pickable.cycles_left = inst.components.pickable.max_cycles
    inst.components.pickable.jostlepick = true
    inst.components.pickable.droppicked = true
    inst.components.pickable.dropheight = 3.5

    inst.components.diseaseable:SetDiseasedFn(ondiseasedfn_juicy)

    inst.components.workable:SetOnWorkCallback(onworked_juicy)
    inst.components.workable:SetOnFinishCallback(dig_up_juicy)
end

return createbush("berrybush", "berrybush", "berrybush", "berries", true, normal_postinit),
    createbush("berrybush2", "berrybush2", "berrybush2", "berries", false, normal_postinit),
    createbush("berrybush_juicy", "berrybush_juicy", "berrybush_juicy", "berries_juicy", true, juicy_postinit)
